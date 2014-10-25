#!/usr/bin/python
# Marcin K Szczodrak
# Updated on 4/24/2014

import os
import sys
sys.path.append("%s/support/sdk/python" % (os.environ["FENNEC_FOX_LIB"]))
from dbgs_h import *

if len(sys.argv) != 2:
	print("\nusage: %s <results.txt>\n\n");
	sys.exit(1)

f = open(sys.argv[1], "r")

for line in f.readlines():
	l = line.split()

	if not l[0].isdigit():
		continue

	time_stamp_sec = int("%s"%(l[0]))
	time_stamp_ms = int("%s"%(l[1]))
	mote_id = int("%s"%(l[2]))

	did = int("%s"%(l[4]))
	dbg = int("%s"%(l[5]))
	dbg_str = dbg_translate(dbg)
	d0 = int("%s"%(l[6]))
	d1 = int("%s"%(l[7]))
	d2 = int("%s"%(l[8]))

	print "{:>8} {:03}".format(time_stamp_sec, time_stamp_ms),
	print "{:>7} ".format(mote_id),
	print "{:>5} ".format(did),
	print "{:>35} ".format(dbg_str),
	print "{:>5} ".format(d0),
	print "{:>5} ".format(d1),
	print "{:>5} ".format(d2)

