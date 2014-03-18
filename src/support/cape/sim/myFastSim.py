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
		#self.dbg_channels = ["Application", "Network"]
		self.dbg_channels = ["Application", "Network", "Mac", "Radio", "Fennec", "FennecEngine", "NetworkState", "NetworkProcess", "StateSynchronization", "Mac-Detail"]
		#self.dbg_channels = ["Application", "Radio", "Fennec", "NetworkState", "StateSynchronization"]
		#self.dbg_channels = ["Application", "Fennec", "NetworkState", "StateSynchronization"]
		#self.dbg_channels = ["Application", "Network", "Mac", "Radio", "Fennec", "StateSynchronization"]
		#self.cape.setTopologyFile("topos/81/linkgain.out")
		self.cape.setTopologyFile("topos/4/linkgain.out")
		self.cape.setNoiseFile("noise/casino.txt")
		self.cape.setSimulationTime(1000)
		
		self.cape.setup()
		
		for dbg_channel in self.dbg_channels:
			self.cape.addDbg(dbg_channel)

		self.traces = []
		self.index = 0



	def run(self):
		for t in self.cape:
			pass



if __name__ == "__main__":
	if len(sys.argv) != 1:
		print "usage: %s"
		sys.exit(1)

	sim = Simulator()
	sim.run()

