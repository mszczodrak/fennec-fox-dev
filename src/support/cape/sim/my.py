#!/usr/bin/python

import Cape 


if __name__ == "__main__":
	print dir(Cape.Cape())
	sim = Cape.Cape()
	sim.setup()
	for dbg_channel in ["Application", "Network", "CapeInput"]:
		sim.addDbg(dbg_channel)
	sim.run()
