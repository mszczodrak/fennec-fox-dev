#!/usr/bin/python
# Marcin K Szczodrak
# Updated on 4/24/2014

import sys
tossim_log = 9


if len(sys.argv) != 2:
	print("\nusage: %s <tossim.dat log file>\n\n");
	sys.exit(1)

f = open(sys.argv[1], "r")

time_offset = -1 

print "{:>8} {:>3} {:>7} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6}".format("sec", "ms", "mote", "ver", "id", "dbg", "d0", "d1", "d2")

for line in f.readlines():
	l = line.split()
	
	if len(l) != tossim_log:
		continue

	if l[1] != "DEBUG":
		continue

	try:
		tl = [float(x) for x in l[0].split(':')]
		time_stamp = int((((tl[0] * 60) + tl[1]) * 60) * 1000 + (1000 * tl[2]))
		mote_id = int("%s"%(l[2][1:-2]))

		version = int("%s"%(l[3]))
		did = int("%s"%(l[4]))
		dbg = int("%s"%(l[5]))
		d0 = int("%s"%(l[6]))
		d1 = int("%s"%(l[7]))
		d2 = int("%s"%(l[8]))
	except:
		continue

	if (time_offset < 0):
		time_offset = time_stamp

	time_stamp = time_stamp - time_offset

	print "{:>8} {:03}".format(time_stamp/1000, time_stamp%1000),
	print "{:>7} ".format(mote_id),
	print "{:>5} ".format(version),
	print "{:>5} ".format(did),
	print "{:>5} ".format(dbg),
	print "{:>5} ".format(d0),
	print "{:>5} ".format(d1),
	print "{:>5} ".format(d2)

