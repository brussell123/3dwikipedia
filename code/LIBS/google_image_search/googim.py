"""Various hooks to access stuff from the web"""
import os, sys, time
import urllib

def spawnWorkers(num, target, name=None, args=(), kwargs={}, daemon=1, interval=0):
    """Spawns the given number of workers, by default daemon, and returns a list of them.
    'interval' determines the time delay between each launching"""
    from threading import Thread
    threads = []
    for i in range(num):
        t = Thread(target=target, name=name, args=args, kwargs=kwargs)
        t.setDaemon(daemon)
        t.start()
        threads.append(t)
        time.sleep(interval)
    return threads

def dlmany(urls, fnames, nprocs=10, callback=None):
    """Downloads many images simultaneously.
    The callback is called with (index, url, fname)"""
    from urllib import urlretrieve
    from Queue import Queue
    assert len(urls) == len(fnames)
    if not urls: return []
    ret = []
    q = Queue()
    outq = Queue()
    def dlproc():
        while 1:
            u, f = q.get()
            if not u: break
            try:
                os.makedirs(os.path.dirname(f))
            except OSError: pass
            try:
                fname, junk = urlretrieve(u, f)
                outq.put((u,fname))
            except Exception, e:
                print >>sys.stderr, 'Exception on %s -> %s: %s' % (u, f, e)
                outq.put((u,None))

    threads = spawnWorkers(nprocs, dlproc, interval=0)
    for u, f in zip(urls, fnames):
        q.put((u, f))
    i = 0
    while len(ret) < len(urls):
        u, f = outq.get()
        if callback:
            callback(i, u, f)
        ret.append((u, f))
        i += 1
    return ret

class CustomURLopener(urllib.FancyURLopener):
    """Custom url opener that defines a new user-agent.
    Needed so that sites don't block us as a crawler."""
    version = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5"

    def prompt_user_passwd(host, realm):
        """Custom user-password func for downloading, to make sure that we don't block"""
        return ('', '')

urllib._urlopener = CustomURLopener()


def checkAndDeleteImgs(fnames):
    """Checks the given set of image filenames for validity.
    If any filename is invalid, deletes it from disk.
    Returns a list of valid fnames, in the same order as given.
    """
    ret = []
    todel = []
    # try to open each file as an image
    for fname in fnames:
        try:
            Image.open(fname)
            ret.append(fname)
        except IOError:
            todel.append(fname)
    # remove bad images from disk
    for fname in todel:
        try:
            os.remove(fname)
        except Exception:
            pass
    return ret


class GoogleImages(object):
    """A google images searcher"""
    def __init__(self,outdir):
        """Initializes with simple setup"""
        self.outdir = outdir

    def _dl(self, q, dir, n_images):
        """Main internal download function.
        Given a search term as 'q', downloads images to our outdir.
        Returns (allret, urls, fnames), where:
            allret is a list of result dicts from google images
            urls is a list of thumbnail urls
            fnames is a list of downloaded image paths
        Note that the output images are at self.outdir/q/imageid.jpg
        """
        import urllib2
        from urllib import quote_plus
        try:
            import simplejson as json
        except ImportError:
            import json
        times = [time.time()]
        allret = []
        # get all metadata
        for start in [0, 8, 16, 24, 32, 40, 48, 56]:
            # Get userip from text file:
            f_ip = open('userip.txt','r')
            myuserip = f_ip.readlines()
            f_ip.close()

            # note that we exclude very small image sizes
            d = dict(userip=myuserip[0].rstrip(), sizes='small|medium|large|xlarge|xxlarge|huge', q=quote_plus(q), start=start)
            url = 'https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%(q)s&userip=%(userip)s&rsz=8&start=%(start)d&imgsz=%(sizes)s' % (d)
            request = urllib2.Request(url, None, {'Referer': 'http://cnet.com/'})
            times.append(time.time())
            response = urllib2.urlopen(request)
            times.append(time.time())
            results = json.load(response)
            allret.extend(results['responseData']['results'])
            times.append(time.time())
        allret = allret[0:n_images]
        # create output dir
        #dir = os.path.join(self.outdir, str(n_images), q.replace(' ','_'))
        try:
            os.makedirs(dir)
        except OSError: pass
        times.append(time.time())
        # start downloading images
        urls, fnames = zip(*[(r['url'], os.path.join(dir, '%04d.jpg' % i)) for i,r in enumerate(allret)])
        #imgs = dlmany(urls, fnames, nprocs=16, callback=None)
        times.append(time.time())
        #print getTimeDiffs(times)
        return (allret, urls, fnames)

    def getthumbs(self, term, dirname, n_images):
        """Downloads all thumbnails for the given term (if needed).
        Checks for a json file in the appropriate location first.
        Returns a list of valid image filenames."""
        try:
            import simplejson as json
        except ImportError:
            import json
        dir = os.path.join(self.outdir, dirname)
        jsonfname = os.path.join(dir, 'index.json')
        # save the search term to a file
        try:
            os.makedirs(dir)
        except OSError: pass
        term_fname = os.path.join(dir,'search_term.txt')
        termfile = open(term_fname,'w')
        print>>termfile,term
        termfile.close()
        try:
            results = json.load(open(jsonfname))
        except Exception:
            # we don't have valid results, so re-download
            ret, urls, fnames = self._dl(term,dir,n_images)
            results = dict(results=ret, thumburls=urls, thumbfnames=fnames)
            json.dump(results, open(jsonfname, 'w'), indent=2)
        # at this point, we have results one way or the other
        return results['thumbfnames']

def testgoog(terms,dirpath):
    """Tests the google image downloader"""
    G = GoogleImages(outdir=dirpath)
    for n_images in [20]:
        for i,term in enumerate(terms):
            done = 0
            counter = 0
            MAX_COUNT = 10
            while not done:
                try:
                    t1 = time.time()
                    ret = G.getthumbs(term,'%04d'%i,n_images)
                    print ret, len(ret), time.time()-t1
                    done = 1
                except Exception, e:
                    counter = counter+1
                    print 'Caught exception %s, so sleeping for a bit' % (e,)
                    if counter < MAX_COUNT:
                        time.sleep(10)
                    else:
                        done = 1
            time.sleep(1)

if __name__ == '__main__':
    testgoog(sys.argv[2:],sys.argv[1])

