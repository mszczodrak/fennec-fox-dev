#!/usr/bin/env python

import os
import sys
import random
import time
sys.path.append(os.environ['FENNEC_FOX_LIB'])
from TOSSIM import *

class Simulation:

	def __init__(self):
		self.enable_sf = 0

		if not os.path.isdir("./results"):
			os.mkdir("./results")

		self.s_tossim = Tossim([])
		if (self.enable_sf):
			self.s_sf = SerialForwarder(9002)
			self.throttle = Throttle(self.s_tossim, 10)	
		self.s_radio = self.s_tossim.radio()
		self.s_topology_file = "topos/36/linkgain.out"
		self.s_irradiance = "irradiance/irradiance_trace.txt"
		self.s_output_file = ""
		self.s_number_of_nodes = 0
		self.s_max_boot_time = 5
		self.s_simulation_time = 25 # Atleast 25 
		self.s_topology = ""
		self.s_noise = "noise/casino.txt"

		self.setup()

		self.addNodesAndChannels()
		self.loadNoiseToNodes()


	def setup(self):
		self.s_tossim.randomSeed(int(time.time()))
		self.s_tossim.init()
		if (self.enable_sf):
			self.s_sf.process()
			self.throttle.initialize()


	def addNodesAndChannels(self):
		temp_file = open(self.s_topology_file, "r")
		for line in temp_file.readlines():
			s = line.split()
			if len(s) > 0:
				if s[0] == "gain":
					self.s_number_of_nodes = max(int(s[1]), int(s[2]), self.s_number_of_nodes)
					self.s_radio.add(int(s[1]), int(s[2]), float(s[3]))

		self.s_number_of_nodes = self.s_number_of_nodes + 1
		temp_file.close()    


	def addDbgChannels(self, run_id):
		self.s_output_file = open("results/results_%d.txt"%(i,),"w")

		#self.s_tossim.addChannel("AM", self.s_output_file)
		#self.s_tossim.addChannel("CpmModelC", self.s_output_file)
		#self.s_tossim.addChannel("TossimPacketModelC", self.s_output_file)
		#self.s_tossim.addChannel("EHP", self.s_output_file)
		#self.s_tossim.addChannel("LI", self.s_output_file)
		#self.s_tossim.addChannel("Dbgs", self.s_output_file)
		self.s_tossim.addChannel("Application", self.s_output_file)
		#self.s_tossim.addChannel("Network", self.s_output_file)
		#self.s_tossim.addChannel("Mac", self.s_output_file)
		#self.s_tossim.addChannel("Radio", self.s_output_file)
		#self.s_tossim.addChannel("Caches", self.s_output_file)
		#self.s_tossim.addChannel("FennecEngine", self.s_output_file)
		#self.s_tossim.addChannel("NetworkScheduler", self.s_output_file)
		#self.s_tossim.addChannel("ProtocolStack", self.s_output_file)
		#self.s_tossim.addChannel("StateSynchronization", self.s_output_file)
		#self.s_tossim.addChannel("Fennec", self.s_output_file)
		#self.s_tossim.addChannel("System", self.s_output_file)
		#self.s_tossim.addChannel("TricklePlus", self.s_output_file)
		#self.s_tossim.addChannel("LI", self.s_output_file)
		#self.s_tossim.addChannel("RoutingTimer", self.s_output_file)
		#self.s_tossim.addChannel("Memory", self.s_output_file)
		#self.s_tossim.addChannel("ConfigurationCache", self.s_output_file)
		#self.s_tossim.addChannel("EventCache", self.s_output_file)
		#self.s_tossim.addChannel("PolicyCache", self.s_output_file)
		#self.s_tossim.addChannel("Events", self.s_output_file)
		#self.s_tossim.addChannel("Sensor", self.s_output_file)
		#self.s_tossim.addChannel("TemperatureEvent", self.s_output_file)
		#self.s_tossim.addChannel("Serial", self.s_output_file)
		#self.s_tossim.addChannel("Forwarder", self.s_output_file)
		#self.s_tossim.addChannel("TreeRoutingCtl", self.s_output_file)
		#self.s_tossim.addChannel("TreeRouting", self.s_output_file)
		#self.s_tossim.addChannel("Irradiance", self.s_output_file)
		#self.s_tossim.addChannel("IrradianceModel", self.s_output_file)
		#self.s_tossim.addChannel("SolarCell", self.s_output_file)
		#self.s_tossim.addChannel("Energy", self.s_output_file)


	def loadNoiseToNodes(self):
		for i in range(self.s_number_of_nodes):
			m = self.s_tossim.getNode(i)

			temp_file = open(self.s_noise, "r")
			for j in temp_file.readlines():
				if len(j) > 0:
					m.addNoiseTraceReading(int(j))
			m.createNoiseModel()
			m.bootAtTime((self.s_tossim.ticksPerSecond() / 50) * i + 43);

	def loadIrradianceToNodes(self):
		for line in self.s_irradiance:
			s = line.split()
			if (len(s) > 0):
				for id in range(self.s_number_of_nodes):
					self.s_tossim.getNode(id).addIrradianceTraceReading(float(s[0]))

 
	def runSingleSimulation(self):
		sim_time = 0

		if (self.enable_sf):
			while True:
				#print self.s_tossim.time()
				self.throttle.checkThrottle();
				if sim_time == (int(self.s_tossim.time()) / self.s_tossim.ticksPerSecond()):
					sim_time += self.s_simulation_time / 25
				self.s_tossim.runNextEvent()
				self.s_sf.process()
		else:
			while sim_time < self.s_simulation_time:
				if sim_time == (int(self.s_tossim.time()) / self.s_tossim.ticksPerSecond()):
					sim_time += self.s_simulation_time / 25
				self.s_tossim.runNextEvent()


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

