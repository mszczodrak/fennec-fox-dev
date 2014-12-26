#!/usr/bin/python
# Marcin K Szczodrak
# Updated on 4/24/2014

import sys
import csv
from operator import itemgetter

twist_log_length = 3
dbgs_len = 34

if len(sys.argv) != 2:
	print("\nusage: %s <serial.csv log file>\n\n");
	sys.exit(1)

f = open(sys.argv[1], "r")

time_offset = -1 

print "{:>8} {:>3} {:>7} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6}".format("sec", "micro", "mote", "ver", "id", "dbg", "d0", "d1", "d2")

data = []

for line in f.readlines():
	if line[0] == "#":
		continue

	l = line.split()

	if len(l) != twist_log_length:
		continue

	if not l[0][0].isdigit():
		continue

	try:
		timestamp = l[0].split(".")
		timestamp_sec = int(float(timestamp[0]))
		timestamp_milli = int(float(timestamp[1]) / 1000.0) 
		mote_id = int(float(l[1]))
		dbgs_msg = l[2]

		if len(dbgs_msg) != dbgs_len:
			continue

		destination = dbgs_msg[:4]
		source = dbgs_msg[4:8]
		msg_len = dbgs_msg[8:10]
		group_id = dbgs_msg[10:12]
		am_type = dbgs_msg[12:14]
		payload = dbgs_msg[16:]

		version = int(payload[:2], 16)
		did = int(payload[2:4], 16)
		dbg = int(payload[4:6], 16)
		d0 = int(payload[6:10], 16)
		d1 = int(payload[10:14], 16)
		d2 = int(payload[14:18], 16)
		
	except:
		continue

	if (time_offset < 0):
		time_offset = timestamp_sec

	timestamp_sec = timestamp_sec - time_offset

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

