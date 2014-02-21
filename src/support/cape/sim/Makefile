SUBDIRS = topos results
TELOSBSENSORSDIR = ../../../Application/tests/TelosbSensors/
TELOSBPKT=$(TELOSBSENSORSDIR)/TelosbSensors.h

ROOT = .
include $(ROOT)/Makefile.include

all: TelosbMsg.py

TelosbMsg.py: $(TELOSBPKT)
	mig python -python-classname=TelosbMsg $(TELOSBPKT) telosb_sensors -o TelosbMsg.py

clean:
	rm TelosbMsg.p*
	rm *.pyc
