#!/usr/bin/python
# Marcin K Szczodrak
# Updated on 4/24/2014

import sys
import csv
from operator import itemgetter

flocklab_log_length = 5

if len(sys.argv) != 2:
	print("\nusage: %s <serial.csv log file>\n\n");
	sys.exit(1)

f = open(sys.argv[1], "r")

time_offset = -1 

print "{:>8} {:>6} {:>7} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6}".format("sec", "micro", "mote", "ver", "id", "dbg", "d0", "d1", "d2")

data = []

all_lines = [line.split(",") for line in f.readlines()]
all_lines.sort(key=lambda x: x[0] )

for l in all_lines:
	if len(l) != flocklab_log_length:
		continue

	if not l[0][0].isdigit():
		continue

	try:
		timestamp = l[0].split(".")
		timestamp_sec = int(float(timestamp[0]))
		timestamp_micro = int(float(timestamp[1]))
		mote_id = int(float(l[1]))
		if l[3] == "r":
			receive = True
		else:
			receive = False


		dbgs_msg = l[4]

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
			"timestamp_micro":timestamp_micro,
			"mote_id":mote_id,
			"version":version,
			"did":did,
			"dbg":dbg,
			"d0":d0,
			"d1":d1,
			"d2":d2})

data.sort(key=lambda d: (d["timestamp_sec"], d["timestamp_micro"]))

for d in data:
	print "{:>8} {:06}".format(d["timestamp_sec"], d["timestamp_micro"]),
	print "{:>7} ".format(d["mote_id"]),
	print "{:>5} ".format(d["version"]),
	print "{:>5} ".format(d["did"]),
	print "{:>5} ".format(d["dbg"]),
	print "{:>5} ".format(d["d0"]),
	print "{:>5} ".format(d["d1"]),
	print "{:>5} ".format(d["d2"])

