#!/usr/bin/python
# Author: Marcin Szczodrak
# Email: marcin@ieee.org
# Last Update: 12/05/2013


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

