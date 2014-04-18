Z1PKT=Z1Sensors.h

all: Z1Msg.py

Z1Msg.py: $(Z1PKT)
	mig python -python-classname=Z1Msg $(Z1PKT) z1_sensors -o Z1Msg.py

clean:
	rm *.pyc

