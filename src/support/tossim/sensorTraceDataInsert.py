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

# Remotely insert sensor data
#
# @author Marcin Szczodrak
# @date   February 16 2014


import sys
import signal

from socket import *
from struct import *
import time
import math

class RemoteSensorInsert():
	def __init__(self, ip_address, ip_port):
		self.ip_address = ip_address
		self.ip_port = int(ip_port)
		try:
			self.sock = socket(AF_INET, SOCK_STREAM)
			self.sock.connect((self.ip_address, self.ip_port))
		except:
			print "Failed to connect to %s:%d" % (self.ip_address, self.ip_port)
			sys.exit(1)

		signal.signal(signal.SIGINT, self.__signal_handler)

		self.number_of_sensors = 4

		self.hum = 0
		self.temp = 0
		self.light = 0

		self.sleep_time = 1

		self.trace = []
		self.trace_index = 0
		self.start_time = 0

		msg = self.sock.recv(1000)
		print msg


	def open_trace_file(self, file_name):
		fin = open(file_name, 'r')
		for l in fin.readlines():
			if l[0] == "#":
				continue
			line = l.split()
			if len(line) != 5:
				continue

			d = {}
			self.trace.append({'time':int(line[0]),
					'mote':int(line[1]),
					'temp':int(line[2]),
					'motion':int(line[3]),
					'co2':int(line[4])})

		fin.close()



	def run(self):
		self.__run = True
		self.start_time = time.time()
		while(self.__run):
			while(self.__sendSensorMeasurements()):
				pass
			time.sleep(self.sleep_time)


	def __sendSensorMeasurements(self):
		if self.trace_index >= len(self.trace):
			return 0

		current_time = time.time() - self.start_time

		if self.trace[self.trace_index]["time"] > current_time:
			return 0

		try:
			msg_si = pack("!HHL", self.trace[self.trace_index]["mote"],
					0, self.trace[self.trace_index]["temp"])
			self.sock.send(msg_si)
			msg_si = pack("!HHL", self.trace[self.trace_index]["mote"],
					1, self.trace[self.trace_index]["motion"])
			self.sock.send(msg_si)
			msg_si = pack("!HHL", self.trace[self.trace_index]["mote"],
					2, self.trace[self.trace_index]["co2"])
			self.sock.send(msg_si)

		except:
			print "Failed to send message"
			self.__run = False
			return 0

#		print "Mote %d  Temp %d  Motion %d  CO2 %d" % ( 
#				self.trace[self.trace_index]["mote"],
#				self.trace[self.trace_index]["temp"],
#				self.trace[self.trace_index]["motion"],
#				self.trace[self.trace_index]["co2"])

		self.trace_index += 1
		return 1


	def __signal_handler(self, sig, frame):
		self.__run = False
		self.sock.close()



if __name__ == "__main__":
	server_ip = '127.0.0.1'
	server_port = '9003'
	trace_file = ''

	if len(sys.argv) != 4 and len(sys.argv) != 2:
		print "usage: %s <ip> <port> <trace_log>" % (sys.argv[0])
		print "ex: $ %s 127.0.0.1 9003 file.txt" % (sys.argv[0])
		sys.exit(1)

	if len(sys.argv) == 4:
		server_ip = sys.argv[1]
		server_port = sys.argv[2]
		trace_file = sys.argv[3]
	else:
		trace_file = sys.argv[1]

	r = RemoteSensorInsert(server_ip, server_port)
	r.open_trace_file(trace_file)
	r.run()
	

