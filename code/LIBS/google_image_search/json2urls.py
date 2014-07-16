import sys
import json

infile = open(sys.argv[1],'r')
if len(sys.argv) > 2:
    outfile = open(sys.argv[2],'w')
else:
    outfile = sys.stdout

js = json.load(infile)

for x in js['results']:
    outfile.write(x['url']+'\n')

infile.close()
outfile.close()
