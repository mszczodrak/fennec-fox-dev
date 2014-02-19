#!/usr/bin/python

import Cape 

def sensorOutput(node_id, val):
	print node_id, val
	pass




k = 10

if __name__ == "__main__":
	print dir(Cape.Cape())
	sim = Cape.Cape()
	sim.setup()
	sim.readIOfun(sensorOutput)
	for dbg_channel in ["Application", "Network", "CapeInput"]:
		sim.addDbg(dbg_channel)

	for t in sim:
		if t > k:
			for n in range(4):
				sim.writeIO(n, k, 0)
			k += 10
		print t
