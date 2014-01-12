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
	def __init__(self, ip_address, ip_port, sf_log):
		self.log_file = sf_log
		self.log = ''
		self.log_counter = 1
		self.ip_address = ip_address
		self.ip_port = ip_port
		self.mif = MoteIF.MoteIF()
		self.tos_source = self.mif.addSource("sf@%s:%s" % (self.ip_address, ip_port))
		self.mif.addListener(self, DebugMsg.DebugMsg)

		if self.log_file != "":
			self.log = open(self.log_file, 'w')
			self.log.write("layer\tstate\taction\td0\td1\tinsert_time\tmotelabMoteID\tmilli_time\tmotelabSeqNo\n")


	def receive(self, src, msg):
		tt = time.time()
		date = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(tt))
		m = "%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d" % (msg.get_layer(), msg.get_state(),
			msg.get_action(), msg.get_d0(), msg.get_d1(),
				date, 0, tt * 1000, self.log_counter)
		self.log_counter += 1

		if self.log != '':
			self.log.write("%s\n" % (m))
			self.log.flush()
		else:
			print m
		
	

	
		#src = msg.get_src()
		#seq = msg.get_seq()
		#freq = msg.get_freq()
		#data = msg.get_data()
		#print data


	def run(self):
		while 1:
			pass






if __name__ == "__main__":
	

	if len(sys.argv) < 3:
		print "\n\nusage: %s <ip_address> <ip_port> [file_log]" % (sys.argv[0])
		print "ex: $ %s 127.0.0.1 9002" % (sys.argv[0])
		sys.exit(1)

	sf_ip = sys.argv[1]
	sf_port = sys.argv[2]
	sf_log = ""
	if len(sys.argv) == 4:
		sf_log = sys.argv[3]

	g = UARTGateway(sf_ip, sf_port, sf_log)
	g.run()







