DebugMsg.class: DebugMsg.java
	javac -target 1.4 -source 1.4 *.java

DebugMsg.java:
	mig java -target=null -java-classname=DebugMsg DebugMsg.h debug_msg -o $@

clean:
	if [ -f caches.h ]; 		then 	rm caches.h; fi
	if [ -f modules.h ]; 		then 	rm modules.h; fi
	if [ -f defparms.h ]; 		then 	rm defparms.h; fi
	if [ -f FennecEngineC.nc ]; 	then 	rm FennecEngineC.nc; fi
	if [ -f FennecEngineP.nc ]; 	then 	rm FennecEngineP.nc; fi
	if [ -f *.java ]; 		then 	rm *.java; fi
	if [ -f *.class ]; 		then 	rm *.class; fi
