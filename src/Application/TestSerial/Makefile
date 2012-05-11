TestSerialMsg.class: TestSerialMsg.java
	javac -target 1.4 -source 1.4 *.java

TestSerialMsg.java:
	mig java -target=null -java-classname=TestSerialMsg TestSerialApp.h serial_pkt -o $@

clean:
	rm *.java *.class
