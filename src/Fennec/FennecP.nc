#include <Fennec.h>

module FennecP {
uses interface Boot;

uses interface Leds;
uses interface SimpleStart as DbgSerial;
uses interface SimpleStart as RandomStart;
uses interface SimpleStart as Caches;
uses interface SimpleStart as ControlUnit;
}

implementation {

event void Boot.booted() {
	//call Leds.led1On();
	call DbgSerial.start();
}

task void start_random() {
	call RandomStart.start();
}

task void start_control_unit() {
	call ControlUnit.start();
}

task void start_caches() {
	call Caches.start();
}

event void DbgSerial.startDone(error_t err) {
	if (err == SUCCESS) {
		post start_random();
	} else {
		call DbgSerial.start();
	}
}

event void RandomStart.startDone(error_t err) {
	if (err == SUCCESS) {
		post start_control_unit();
	} else {
		call RandomStart.start();
	}
}

event void ControlUnit.startDone(error_t err) {
	if (err == SUCCESS) {
		post start_caches();
	} else {
		call ControlUnit.start();
	}
}

event void Caches.startDone(error_t err) {}

}

