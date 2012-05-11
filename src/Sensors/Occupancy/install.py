#!/usr/bin/python
import sys
import os

file_name = "occupancy_trace"

if len(sys.argv) != 3:
	print "\nusage: %s <platform> <mote_id>\n"%(sys.argv[0])
	sys.exit()


os.system("cp %s_%d.txt %s"%(file_name, int(sys.argv[2]), file_name))
os.system("fennec %s install,%d"%(sys.argv[1], int(sys.argv[2])))
#os.system("rm %s"%file_name)
