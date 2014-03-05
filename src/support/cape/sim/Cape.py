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

import signal

class Cape():

	def __init__(self, topology = "topos/4/linkgain.out", 
				noise = "noise/casino.txt", 
				real_time = 0,
				sim_time = 100):
		self.__real_time = real_time

		signal.signal(signal.SIGINT, self.__signal_handler)

		if not os.path.isdir("./results"):
			os.mkdir("./results")

		self.__tossim = Tossim([])
		if (self.__real_time):
		self.__radio = self.__tossim.radio()
		self.__topology_file = topology
		self.__output_file = ""
		self.__number_of_nodes = 0
		self.__run_id = 0
		self.__simulation_end_time = sim_time
		self.__topology = ""
		self.__noise_file = noise
		self.__simulated_time = 0
		self.__start_time = 0
		self.__sf_port = 9002
		self.__sensor_port = 9003
		self.__readFun = None
		self.__stop = False


	def setTopologyFile(self, topology):
		self.__topology_file = topology


	def setNoiseFile(self, noise):
		self.__noise_file = noise


	def setRealTime(self):
		self.__real_time = 1
		self.__sf = SerialForwarder(self.__sf_port)
		self.__sin = SensorInput(self.__sensor_port)
		self.__throttle = Throttle(self.__tossim, 10)


	def setSimulationTime(self, sim_time):
		self.__simulation_end_time = sim_time

	def setSerialPort(self, port):
		self.__sf_port = port

	def setSensorPort(self, port):
		self.__sensor_port = port

	def setup(self):
		self.__tossim.randomSeed(int(time.time()))
		self.__tossim.init()
		if (self.__real_time):
			self.__sf = SerialForwarder(self.__sf_port)
			self.__throttle = Throttle(self.__tossim, 10)	
			self.__sin = SensorInput(self.__sensor_port)
			self.__sf.process()
			self.__sin.process()
			self.__throttle.initialize()

		self.__run_id = self.__run_id + 1
		self.__simulated_time = 0

		self.__output_file = open("results/results_%d.txt" % (self.__run_id),"w")
		self.__addNodesAndChannels()
		self.__loadNoiseToNodes()


	def __signal_handler(self, sig, frame):
		self.__stop = True


	def __addNodesAndChannels(self):
		temp_file = open(self.__topology_file, "r")
		for line in temp_file.readlines():
			s = line.split()
			if len(s) > 0:
				if s[0] == "gain":
					self.__number_of_nodes = max(int(s[1]), int(s[2]), self.__number_of_nodes)
					self.__radio.add(int(s[1]), int(s[2]), float(s[3]))

		self.__number_of_nodes = self.__number_of_nodes + 1
		temp_file.close()    


	def addDbg(self, channel):
		self.__tossim.addChannel(channel, self.__output_file)


	def __loadNoiseToNodes(self):
		for i in range(self.__number_of_nodes):
			m = self.__tossim.getNode(i)

			temp_file = open(self.__noise_file, "r")
			for j in temp_file.readlines():
				if len(j) > 0:
					m.addNoiseTraceReading(int(j))
			m.createNoiseModel()
			m.bootAtTime((self.__tossim.ticksPerSecond() / 50) * i + 43);


	def writeIO(self, node_id, val, channel, sim_time = 0):
		if node_id >= self.__number_of_nodes:
			return 1

		node = self.__tossim.getNode(node_id)
		node.writeInput(val, channel, sim_time)
	

	def readIOfun(self, fun):
		self.__readFun = fun
	

	def __do_IO(self):
		if self.__readFun == None:
			return
		
		for node_id in range(self.__number_of_nodes):
			node = self.__tossim.getNode(node_id)
			# read Actuating Data from every mote
			self.__readFun(node_id, node.readOutput(0, 0))	
			self.__readFun(node_id, node.readOutput(1, 0))	
			self.__readFun(node_id, node.readOutput(2, 0))	
			self.__readFun(node_id, node.readOutput(3, 0))	


	def __runRealTimeSimulation(self):
		if self.__stop:
			raise StopIteration
		else:
			self.__do_IO()
			self.__throttle.checkThrottle();
			self.__tossim.runNextEvent()
			self.__sf.process()
			self.__sin.process()
			return (1.0 * self.__tossim.time() / self.__tossim.ticksPerSecond())


	def __runFastSimulation(self):
		if self.__stop or (self.__tossim.time() / self.__tossim.ticksPerSecond()) >= \
						self.__simulation_end_time:	
			raise StopIteration
		else:
			self.__do_IO()
			self.__tossim.runNextEvent()
			return (1.0 * self.__tossim.time() / self.__tossim.ticksPerSecond())


	def __iter__(self):
		return self


	def next(self):
		if (self.__real_time):
			return self.__runRealTimeSimulation()
		else:
			return self.__runFastSimulation()



