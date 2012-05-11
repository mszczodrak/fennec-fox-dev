#!/usr/bin/python

import os

pwd = os.getcwd()

job_dirs = [
        "Application",
        "Addressing",
        "Network",
        "Mac",
        "Radio",
        "ControlUnit",
	"interfaces"
        ]

substitutions = [
		["RadioCommands", "RadioCall"],
		["RadioEvents", "RadioSignal"],
		["MacCommands", "MacCall"],
		["MacEvents", "MacSignal"],
		["NetworkCommands", "NetworkCall"],
		["NetworkEvents", "NetworkSignal"],
		["received", "drop_message"]
		]

for job in job_dirs:
        for root, dirs, files in os.walk(job):
		os.chdir("./%s"%root)
		for afile in files:
			for sub in substitutions:	
				os.system("sed s/%s/%s/ < %s > %s.temp"%(sub[0], sub[1], afile, afile))
				os.system("mv %s.temp %s"%(afile, afile))
		os.chdir(pwd)



