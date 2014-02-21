TELOSBPKT=TelosbSensors.h

all: TelosbMsg.py

TelosbMsg.py: $(TELOSBPKT)
	mig python -python-classname=TelosbMsg $(TELOSBPKT) telosb_sensors -o TelosbMsg.py

clean:
	rm TelosbMsg.p*
	rm *.pyc

