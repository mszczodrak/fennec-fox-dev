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

# Example of Cape Simulation instantiation
#
# @author Marcin Szczodrak
# @updated   March 12 2013
#

import os
import sys
import time
import struct

#sys.path.append('./tinyos_sdk_python')

import TelosbMsg

from tinyos.message import *
from tinyos.message.Message import *
from tinyos.message.SerialPacket import *
from tinyos.packet.Serial import Serial

class UARTGateway:
	def __init__(self, ip_address, ip_port):
		self.ip_address = ip_address
		self.ip_port = ip_port
		self.mif = MoteIF.MoteIF()
		self.tos_source = self.mif.addSource("sf@%s:%s" % (self.ip_address, ip_port))
		self.mif.addListener(self, TelosbMsg.TelosbMsg)


	def receive(self, src, msg):
		print msg
		if msg.get_amType() == TelosbMsg.AM_TYPE:
	                src = msg.get_src()
	                seq = msg.get_seq()
        	        hum = msg.get_hum()
        	        temp = msg.get_temp()
        	        light = msg.get_light()

			print time.time(), src, seq, hum, temp, light
			#m = TelosbMsg.TelosbMsg(msg.dataGet())

		#sys.stdout.flush()

	def send(self):
		pass
		#smsg = TelosbMsg.TelosbMsg()
		#smsg.set_rx_timestamp(time.time())
		#self.mif.sendMsg(self.tos_source, 0xFFFF,
		#smsg.get_amType(), 0, smsg)

	def run(self):
		while 1:
			pass


if __name__ == "__main__":

	sf_ip = '127.0.0.1'
	sf_port = '9002'

	if len(sys.argv) != 3 and len(sys.argv) != 1:
		print "\n\nusage: %s <ip_address> <ip_port>" % (sys.argv[0])
		print "ex: $ %s 127.0.0.1 9002" % (sys.argv[0])
		sys.exit(1)

	if len(sys.argv) == 3:
		sf_ip = sys.argv[1]
		sf_port = sys.argv[2]

	g = UARTGateway(sf_ip, sf_port)
	try:
		g.run()
	except KeyboardInterrupt:
		pass

