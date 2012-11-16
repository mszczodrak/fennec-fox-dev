#!/usr/bin/python

import sys
from get_layer import *
from get_state import *
from get_action import *
from fennec_h import *
from dbgs_h import *

f = open(sys.argv[1], "r")

min_time = -1

for line in f.readlines():
	l = line.split()
	if len(l) < 2:
		continue

	if l[0] == "layer":
		continue

	layer = int("%s"%(l[0]))
	state = int("%s"%(l[1]))
	action = int("%s"%(l[2]))
	d0 = int("%s"%(l[3]))
	d1 = int("%s"%(l[4]))

	mote_id = int("%s"%(l[7]))
	time_stamp = int("%s"%(l[8]))

	if (min_time < 0):
		min_time = time_stamp

	time_stamp = time_stamp - min_time

	print "{:>6} {:03} ({:}): ".format(time_stamp/1000, time_stamp%1000, mote_id),

	print 'Layer: {:<11} '.format(get_layer(layer)),

	print "State: {:<9} ".format(get_state(state)),

	print "Action: {:<18} ".format(get_action(action)),

	print "Data:[ %s %s ]" % (l[3], l[4]) 
