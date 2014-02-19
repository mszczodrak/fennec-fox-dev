#!/usr/bin/python
#
# Copyright (c) 2014 Columbia University. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the
#   distribution.
# - Neither the name of the copyright holder nor the names of
#   its contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Example of Cape Simulation instantiation
#
# @author Marcin Szczodrak
# @date   February 16 2014

import Cape 
import sys

class Simulator():
	def __init__(self):
		self.cape = Cape.Cape()
		self.dbg_channels = ["Application", "Network", "CapeInput"]
		
		self.cape.setup()
		self.cape.readIOfun(self.readActuatorOutput)
		
		for dbg_channel in self.dbg_channels:
			self.cape.addDbg(dbg_channel)

		self.traces = []
		self.index = 0


	def readActuatorOutput(self, node_id, val):
		print node_id, val


	def writeSensorInput(self, sim_time):
		sim_time_ms = sim_time * 1000
		print sim_time_ms, self.traces[self.index]["t"]
		while (sim_time_ms > self.traces[self.index]["t"]):
			self.cape.writeIO(0, self.traces[self.index]["hum"], 0)
			self.cape.writeIO(0, self.traces[self.index]["temp"], 1)
			self.cape.writeIO(0, self.traces[self.index]["light"], 2)
			self.index += 1
		


	def loadTrace(self, trace_file):
		fin = open(trace_file, "r")
		for l in fin.readlines():
			if l[0] == "#":
				continue

			vals = [int(x) for x in l.split()]
			d = {}
			d["t"] = vals[0]
			d["n"] = vals[1]
			d["hum"] = vals[2]
			d["temp"] = vals[3]
			d["light"] = vals[4]
			self.traces.append(d)


	def run(self):
		self.index = 0
		for t in self.cape:
			self.writeSensorInput(t)	



if __name__ == "__main__":
	if len(sys.argv) != 2:
		print "usage: %s <sensor_trace_file.txt>"
		sys.exit(1)

	sim = Simulator()
	sim.loadTrace(sys.argv[1])
	sim.run()

