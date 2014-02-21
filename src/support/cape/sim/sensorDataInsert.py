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
		self.sock = socket(AF_INET, SOCK_STREAM)
		self.sock.connect((self.ip_address, self.ip_port))
		signal.signal(signal.SIGINT, self.__signal_handler)

		self.number_of_sensors = 4

		self.hum = 0
		self.temp = 0
		self.light = 0

		self.sleep_time = 5

		msg = self.sock.recv(1000)
		print msg


	def run(self):
		self.__run = True
		while(self.__run):
			for node_id in range(self.number_of_sensors):
				msg_si = pack("!HHL", node_id, 0, self.hum)
				self.sock.send(msg_si)
				msg_si = pack("!HHL", node_id, 1, self.temp)
				self.sock.send(msg_si)
				msg_si = pack("!HHL", node_id, 2, self.light)
				self.sock.send(msg_si)
			time.sleep(self.sleep_time)
			self.__updateSensorValue()


	def __updateSensorValue(self):
		self.hum = math.fabs(4 * math.sin(time.time() / 2))
		self.temp = math.fabs(16 * math.sin(time.time() * 2))	
		self.light = math.fabs(32 * math.sin(time.time()))		
		print "Humidity: %d  Temp: %d  Light: %d" % (self.hum, self.temp, self.light) 


	def __signal_handler(self, sig, frame):
		self.__run = False
		self.sock.close()



if __name__ == "__main__":
	server_ip = '127.0.0.1'
	server_port = '9003'

	if len(sys.argv) != 3 and len(sys.argv) != 1:
		print "usage: %s <ip> <port>" % (sys.argv[0])
		print "ex: $ %s 127.0.0.1 9003" % (sys.argv[0])
		sys.exit(1)

	if len(sys.argv) == 3:
		server_ip = sys.argv[1]
		server_port = sys.argv[2]

	r = RemoteSensorInsert(server_ip, server_port)
	r.run()
	

