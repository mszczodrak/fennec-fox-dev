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

class TelosbSerial:
	def __init__(self, uart):
		self.mif = MoteIF.MoteIF()
		self.tos_source = self.mif.addSource(uart)
		self.mif.addListener(self, TelosbMsg.TelosbMsg)

	def receive(self, src, msg):
		if msg.get_amType() == TelosbMsg.AM_TYPE:
			print msg
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
	try:
		if len(sys.argv) != 2:
			print "\n\nusage %s <serial_device:boundrate>"
			print "\n\nex. $ %s serial@/dev/ttyUSB0:115200\n"
			sys.exit(1)
		g = TelosbSerial(sys.argv[1])
		g.run()
		
	except KeyboardInterrupt:
		pass
