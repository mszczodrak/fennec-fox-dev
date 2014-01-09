#!/usr/bin/python
# Author: Marcin Szczodrak
# Email: marcin@ieee.org
# Last Update: 12/05/2013

import os
import sys
import time
import struct

sys.path.append('./tinyos_sdk_python')

import DebugMsg

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
		self.mif.addListener(self, DebugMsg.DebugMsg)


	def receive(self, src, msg):
		print msg
		#src = msg.get_src()
		#seq = msg.get_seq()
		#freq = msg.get_freq()
		#data = msg.get_data()
		#print data


	def run(self):
		while 1:
			pass






if __name__ == "__main__":
	

	if len(sys.argv) != 3:
		print "\n\nusage: %s <ip_address> <ip_port>" % (sys.argv[0])
		print "ex: $ %s 127.0.0.1 9002" % (sys.argv[0])
		sys.exit(1)

	sf_ip = sys.argv[1]
	sf_port = sys.argv[2]

	g = UARTGateway(sf_ip, sf_port)
	g.run()







