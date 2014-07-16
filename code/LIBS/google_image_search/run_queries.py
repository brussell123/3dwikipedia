import googim
import sys

FNAME = sys.argv[1]
f = open(FNAME,'r')
names = [x[0:-1] for x in f.readlines()]
f.close()

googim.testgoog(names,sys.argv[2])
