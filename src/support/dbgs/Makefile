DebugMsg.class: DebugMsg.java
	javac -target 1.4 -source 1.4 *.java

DebugMsg.java:
	mig java -target=null -java-classname=DebugMsg DebugMsg.h debug_msg -o $@

clean:
	if [ -f *.java ]; 		then 	rm *.java; fi
	if [ -f *.class ]; 		then 	rm *.class; fi
