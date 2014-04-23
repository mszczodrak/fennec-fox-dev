SerialDbgs.class: $(wildcard *.java) SerialDbgs.java
	javac -target 1.4 -source 1.4 *.java

SerialDbgs.java:
	mig java -target=null -java-classname=SerialDbgs SerialDbgs.h debug_msg -o $@

clean:
	if [ -f *.java ]; 		then 	rm *.java; fi
	if [ -f *.class ]; 		then 	rm *.class; fi
