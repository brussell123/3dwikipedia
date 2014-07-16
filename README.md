[3D Wikipedia](http://grail.cs.washington.edu/projects/label3d/) source code
===========

Here you will find the Matlab and Python source code for automatically
labeling objects in 3D models given a reference text, such as Wikipedia.


### CITATION:

Bryan C. Russell, Ricardo Martin-Brualla, Daniel J. Butler, Steven M. Seitz, and Luke Zettlemoyer.
3D Wikipedia: Using Online Text to Automatically Label and Navigate Reconstructed Geometry.
ACM Transactions on Graphics (SIGGRAPH Asia 2013), Vol. 32, No. 6.
[PDF](http://grail.cs.washington.edu/projects/label3d/3D_Wikipedia_SIGGRAPH_Asia_2013.pdf) | [Project page](http://grail.cs.washington.edu/projects/label3d/)


### INSTALLATION:

1. For the results in the paper we used the Stanford parser.  You can
download the version we used here:

   http://nlp.stanford.edu/software/stanford-parser-2012-07-09.tgz

   Uncompress the tarball and insert into "./code/LIBS/".

   We found it helpful to raise the memory limit.  You can set the memory
limit inside "stanford-parser-2012-07-09/lexparser.sh" by changing
"-mx1000m" (we set it to be "-mx4000m").

2. To download images from Google Image Search, be sure to set your
user IP address inside the following file before running the scripts:

./code/LIBS/google_image_search/userip.txt

See the following as a reference for the Google Image Search API:

https://developers.google.com/console/help/#activatingapis

3. Download the Bundler tarball:

http://www.cs.cornell.edu/~snavely/bundler/distr/bundler-v0.4-source.tar.gz

Uncompress the tarball and insert into "./code/LIBS/".

4. In Matlab, run "compile" to compile all binaries.


### RUNNING THE CODE:

1. You can run the code demo by downloading the text, reference image,
and pre-computed "bundle" struct for the Pantheon provided on the 3D
Wikipedia project webpage.  Skip to step 2 below.  

To run on your own data, start by building a 3D model of the site.
You will need to download images to build the 3D model, e.g. by
querying Flickr for the site name and downloading images through their
API.  A couple of possibilities for building a sparse 3D point cloud
is via VisualSFM (recommended):

http://ccwu.me/vsfm/

or Bundler:

http://www.cs.cornell.edu/~snavely/bundler/

We provide Matlab scripts to read the sparse point cloud.  To read the
output from VisualSFM (e.g. "pantheon.nvm"), run the following in Matlab:

addpath ./code;
bundle = ReadNVMFile('pantheon.nvm');

To read the output from Bundler (e.g. the output lives in a directory
"/path/to/pantheon"), run the following in Matlab:

addpath ./code;
bundle = readBundleFile('/path/to/pantheon');

2. Given the text, reference image, and "bundle" struct, adjust the
global variables at the top of the "demoDetect.m" script and run in
Matlab.  


---- 

Copyright (C) 2014  Intel, University of Washington, Bryan C. Russell, Ricardo Martin-Brualla, Daniel J. Butler, Steven M. Seitz, Luke Zettlemoyer
