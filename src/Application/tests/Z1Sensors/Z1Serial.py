#!/usr/bin/python
#
# Copyright (c) 2012 Columbia University. All rights reserved.
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

# Read Z1 Sensor Measurements from Serial (UART)
#
# @author Marcin Szczodrak
# @date   March 3 2014

import os
import sys
import time
import struct

import Z1Msg

from tinyos.message import *
from tinyos.message.Message import *
from tinyos.message.SerialPacket import *
from tinyos.packet.Serial import Serial

class Z1Serial:
	def __init__(self, uart):
		self.mif = MoteIF.MoteIF()
		try:
			self.tos_source = self.mif.addSource(uart)
			self.mif.addListener(self, Z1Msg.Z1Msg)
		except:
			print "Failed to connect to %s" % (uart)
			sys.exit(1)


	def receive(self, src, msg):
		if msg.get_amType() == Z1Msg.AM_TYPE:
			print msg
	                #src = msg.get_src()
	                #seq = msg.get_seq()
        	        #temp = msg.get_temp()

		#sys.stdout.flush()

	def send(self):
		node_id = 1
		#msg = Z1Msg.Z1Msg()
		#msg.set_rx_timestamp(time.time())
		#self.mif.sendMsg(self.tos_source, node_id,
		#		msg.get_amType(), 0, msg)

	def run(self):
		while 1:
			pass


if __name__ == "__main__":
	if len(sys.argv) != 2:
		print "\n\nusage %s <serial_device:boundrate>"
		print "\n\nex. $ %s serial@/dev/ttyUSB0:115200\n"
		sys.exit(1)
	g = Z1Serial(sys.argv[1])

	try:
		g.run()
	except KeyboardInterrupt:
		pass
