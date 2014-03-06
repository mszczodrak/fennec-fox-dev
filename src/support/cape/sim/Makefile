SUBDIRS = topos results
TELOSBSENSORSDIR = ../../../Application/tests/TelosbSensors/
TELOSBPKT=$(TELOSBSENSORSDIR)/TelosbSensors.h
Z1SENSORSDIR = ../../../Application/tests/Z1Sensors/
Z1PKT=$(Z1SENSORSDIR)/Z1Sensors.h

ROOT = .
include $(ROOT)/Makefile.include

all: TelosbMsg.py Z1Msg.py

TelosbMsg.py: $(TELOSBPKT)
	mig python -python-classname=TelosbMsg $(TELOSBPKT) telosb_sensors -o TelosbMsg.py


Z1Msg.py: $(Z1PKT)
	mig python -python-classname=Z1Msg $(Z1PKT) z1_sensors -o Z1Msg.py


clean:
	rm TelosbMsg.p*
	rm Z1Msg.p*
	rm *.pyc
