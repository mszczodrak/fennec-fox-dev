
all: DebugMsg.py

DebugMsg.py: DebugMsg.h
	mig python -python-classname=DebugMsg DebugMsg.h debug_msg -o DebugMsg.py

clean:
	rm DebugMsg.p*

