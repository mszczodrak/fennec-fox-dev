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

#
# Cape Python Class
#
# @author Marcin Szczodrak
# @date   February 16 2014


import os
import sys
import random
import time
sys.path.append(os.environ['FENNEC_FOX_LIB'])
from TOSSIM import *


class Cape():

	def __init__(self, topology = "topos/4/linkgain.out", 
				noise = "noise/casino.txt", 
				real_time = 0,
				sim_time = 100):
		self.enable_sf = 0

		if not os.path.isdir("./results"):
			os.mkdir("./results")

		self.s_tossim = Tossim([])
		if (self.enable_sf):
			self.s_sf = SerialForwarder(9002)
			self.throttle = Throttle(self.s_tossim, 10)	
		self.s_radio = self.s_tossim.radio()
		self.__topology_file = "topos/4/linkgain.out"
		self.__output_file = ""
		self.__number_of_nodes = 0
		self.__run_id = 0
		self.s_max_boot_time = 5
		self.s_simulation_time = 100 # Atleast 25 
		self.__topology = ""
		self.__noise_file = "noise/casino.txt"
		self.in_vals = 0
		self.out_vals = 0


	def setTopologyFile(self, topology):
		self.__topology_file = topology

	def setNoiseFile(self, noise):
		self.__noise_file = noise

	def setup(self):
		self.s_tossim.randomSeed(int(time.time()))
		self.s_tossim.init()
		if (self.enable_sf):
			self.s_sf.process()
			self.throttle.initialize()

		self.__run_id = self.__run_id + 1

		self.__addNodesAndChannels()
		self.__loadNoiseToNodes()


	def __addNodesAndChannels(self):
		temp_file = open(self.__topology_file, "r")
		for line in temp_file.readlines():
			s = line.split()
			if len(s) > 0:
				if s[0] == "gain":
					self.__number_of_nodes = max(int(s[1]), int(s[2]), self.__number_of_nodes)
					self.s_radio.add(int(s[1]), int(s[2]), float(s[3]))

		self.__number_of_nodes = self.__number_of_nodes + 1
		temp_file.close()    


	def addDbg(self, channel):
		try:
			self.__output_file = open("results/results_%d.txt" % (self.__run_id),"w")
		except:
			pass

		self.s_tossim.addChannel(channel, self.__output_file)


	def __loadNoiseToNodes(self):
		for i in range(self.__number_of_nodes):
			m = self.s_tossim.getNode(i)

			temp_file = open(self.__noise_file, "r")
			for j in temp_file.readlines():
				if len(j) > 0:
					m.addNoiseTraceReading(int(j))
			m.createNoiseModel()
			m.bootAtTime((self.s_tossim.ticksPerSecond() / 50) * i + 43);


	def do_IO(self):
		time_is = self.s_tossim.time()
		
		for node_id in range(self.s_number_of_nodes):
			node = self.s_tossim.getNode(node_id)
			# write Sensor Data into each mote
			node.writeInput(self.in_vals, 0, 0)

			# read Actuating Data from every mote
			self.out_vals = node.readOutput(0, 0)	
			self.in_vals = self.out_vals + 1


	def runRealTimeSimulation(self):
		sim_time = 0
		while True:
			self.do_IO()
			#print self.s_tossim.time()
			self.throttle.checkThrottle();
			if sim_time == (int(self.s_tossim.time()) / self.s_tossim.ticksPerSecond()):
				sim_time += self.s_simulation_time / 25
			self.s_tossim.runNextEvent()
			self.s_sf.process()


	def runFastSimulation(self):
		sim_time = 0
		while sim_time < self.s_simulation_time:
			self.do_IO()
			if sim_time == (int(self.s_tossim.time()) / self.s_tossim.ticksPerSecond()):
				sim_time += self.s_simulation_time / 25
			self.s_tossim.runNextEvent()


	def runSingleSimulation(self):
		if (self.enable_sf):
			self.runRealTimeSimulation()
		else:
			self.runFastSimulation()


if __name__ == "__main__":

	how_many = int(sys.argv[1])

	for i in range(how_many):
		print "Run %d   "%(i,)
		t = time.time()
		s = Simulation()
		s.addDbgChannels(i)
		print "Time to prepare simulation: %d secs"%(time.time() - t)
		print "Start SF Client"
		#time.sleep(5)
		print "Start Simulation"
		t = time.time()
		s.runSingleSimulation()
		print "Time to run simulation: %d secs"%(time.time() - t)

