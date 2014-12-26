#!/usr/bin/python
# Marcin K Szczodrak
# Updated on 4/24/2014

import sys
twonet_serial_log_length = 15
twonet_printf_log_length = 8

if len(sys.argv) != 2:
	print("\nusage: %s <twonet.dat log file>\n\n");
	sys.exit(1)

f = open(sys.argv[1], "r")

time_offset = -1 

print "{:>8} {:>3} {:>7} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6}".format("sec", "ms", "mote", "ver", "id", "dbg", "d0", "d1", "d2")

data = []

for line in f.readlines():
	l = line.split()

	if len(l) != twonet_serial_log_length and len(l) != twonet_printf_log_length:
		continue

	if l[1] == 'PRINTF:':
		try:
			#time_stamp = int("%s"%(l[0]))
			time_stamp = 0
			mote_id = int("%s"%(l[0]))

			version = int("%s"%(l[2]))
			did = int("%s"%(l[3]))
			dbg = int("%s"%(l[4]))
			d0 = int("%s"%(l[5]))
			d1 = int("%s"%(l[6]))
			d2 = int("%s"%(l[7]))
		except:
			continue

	else:
		if not l[0].isdigit():
			continue

		try:
			#time_stamp = int("%s"%(l[0]))
			time_stamp = 0
			mote_id = int("%s"%(l[0]))

			version = int("%s"%(l[6][1:-1]))
			did = int("%s"%(l[7][:-1]))
			dbg = int("%s"%(l[8][:-1]))
			d0 = int("%s"%(l[9][:-1])) * 256 + int("%s"%(l[10][:-1]))
			d1 = int("%s"%(l[11][:-1])) * 256 + int("%s"%(l[12][:-1]))
			d2 = int("%s"%(l[13][:-1])) * 256 + int("%s"%(l[14][:-2]))
		except:
			continue



	if (time_offset < 0):
		time_offset = time_stamp

	time_stamp = time_stamp - time_offset

	data.append({"timestamp_sec":timestamp_sec,
			"timestamp_milli":timestamp_milli,
			"mote_id":mote_id,
			"version":version,
			"did":did,
			"dbg":dbg,
			"d0":d0,
			"d1":d1,
			"d2":d2})

data.sort(key=lambda d: (d["timestamp_sec"], d["timestamp_milli"]))

for d in data:
	print "{:>8} {:03}".format(d["timestamp_sec"], d["timestamp_milli"]),
	print "{:>7} ".format(d["mote_id"]),
	print "{:>5} ".format(d["version"]),
	print "{:>5} ".format(d["did"]),
	print "{:>5} ".format(d["dbg"]),
	print "{:>5} ".format(d["d0"]),
	print "{:>5} ".format(d["d1"]),
	print "{:>5} ".format(d["d2"])

