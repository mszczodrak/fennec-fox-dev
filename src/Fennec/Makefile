DebugMsg.class: DebugMsg.java
	javac -target 1.4 -source 1.4 *.java

DebugMsg.java:
	mig java -target=null -java-classname=DebugMsg DebugMsg.h debug_msg -o $@

clean:
	if [ -d sfc ];			then	rm -rf sfc; fi
	if [ -f FennecEngineC.nc ]; 	then 	rm FennecEngineC.nc; fi
	if [ -f FennecEngineP.nc ]; 	then 	rm FennecEngineP.nc; fi
	if [ -f *.java ]; 		then 	rm *.java; fi
	if [ -f *.class ]; 		then 	rm *.class; fi
