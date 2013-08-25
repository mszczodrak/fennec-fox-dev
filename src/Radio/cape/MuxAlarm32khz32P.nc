//#include <MicaTimer.h>

generic module MuxAlarm32khz32P()
{
	provides interface Alarm<T32khz, uint32_t>;
	uses interface Timer<TMilli>;
}
implementation
{

uint32_t cMilliTo32khz(uint32_t t) {
	if (t == 0) return 1;
	return t * 32768 / 1000;
}

uint32_t c32khzToMilli(uint32_t t) {
	if (t == 0) return 1;
	return t * 1000 / 32768; 
}

event void Timer.fired() {
	signal Alarm.fired();
}

async command void Alarm.start( uint32_t t ) {
	dbg("Alarm", "VirtualizeAlarm Alarm start");
	call Timer.startOneShot( c32khzToMilli(t) );
}

async command void Alarm.stop() {
	call Timer.stop();
}


async command bool Alarm.isRunning() {
}

async command void Alarm.startAt( uint32_t t0, uint32_t dt ) {
    dbg("Alarm", "VirtualizeAlarm Alarm startAt hhhh");
}

async command uint32_t Alarm.getNow() {
}

async command uint32_t Alarm.getAlarm() {
}

default async event void Alarm.fired() {
}


}
