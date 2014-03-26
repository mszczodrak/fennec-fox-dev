#include <Tasklet.h>

generic module cc2420xCollisionLayerP() {

provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;

/* wire to Slotted */
uses interface RadioSend as SlottedRadioSend;
uses interface RadioReceive as SlottedRadioReceive;

provides interface RadioSend as SlottedSubSend;
provides interface RadioReceive as SlottedSubReceive;
provides interface RadioAlarm as SlottedRadioAlarm;
provides interface SlottedCollisionConfig as SlottedConfig;


/* wire to Random */
uses interface RadioSend as RandomRadioSend;
uses interface RadioReceive as RandomRadioReceive;

provides interface RadioSend as RandomSubSend;
provides interface RadioReceive as RandomSubReceive;
provides interface RadioAlarm as RandomRadioAlarm;
provides interface RandomCollisionConfig as RandomConfig;

}

implementation {

bool slotted = FALSE;

tasklet_async command error_t RadioSend.send(message_t* msg) {
	if (slotted) {
		return call SlottedRadioSend.send(msg);
	} else {
		return call RandomRadioSend.send(msg);
	}
}

/*
	Sub Events
*/

tasklet_async event void SubSend.ready() {
	if (slotted) {
		return signal SlottedSubSend.ready();
	} else {
		return signal RandomSubSend.ready();
	}
}

tasklet_async event void SubSend.sendDone(error_t error) {
	if (slotted) {
		return signal SlottedSubSend.sendDone(error);
	} else {
		return signal RandomSubSend.sendDone(error);
	}
}

tasklet_async event bool SubReceive.header(message_t* msg) {
	if (slotted) {
		return signal SlottedSubReceive.header(msg);
	} else {
		return signal RandomSubReceive.header(msg);
	}
}

tasklet_async event message_t* SubReceive.receive(message_t* msg) {
	if (slotted) {
		return signal SlottedSubReceive.receive(msg);
	} else {
		return signal RandomSubReceive.receive(msg);
	}
}

tasklet_async event void RadioAlarm.fired() {
	if (slotted) {
		return signal SlottedRadioAlarm.fired();
	} else {
		return signal RandomRadioAlarm.fired();
	}
}

/* 
	Slotted Commands
*/


tasklet_async command error_t SlottedSubSend.send(message_t* msg) {
	return call SubSend.send(msg);
}

tasklet_async command bool SlottedRadioAlarm.isFree() {
	return call RadioAlarm.isFree();
}

tasklet_async command void SlottedRadioAlarm.wait(tradio_size timeout) {
	return call RadioAlarm.wait(timeout);
}

tasklet_async command void SlottedRadioAlarm.cancel() {
	return call RadioAlarm.cancel();
}

async command tradio_size SlottedRadioAlarm.getNow() {
	return call RadioAlarm.getNow();
}

async command uint16_t SlottedConfig.getInitialDelay() {
	return call SlottedCollisionConfig.getInitialDelay();
}

async command uint8_t SlottedConfig.getScheduleExponent() {
	return call SlottedCollisionConfig.getScheduleExponent();
}

async command uint16_t SlottedConfig.getTransmitTime(message_t* msg) {
	return call SlottedCollisionConfig.getTransmitTime(msg);
}

async command uint16_t SlottedConfig.getCollisionWindowStart(message_t* msg) {
	return call SlottedCollisionConfig.getCollisionWindowStart(msg);
}

async command uint16_t SlottedConfig.getCollisionWindowLength(message_t* msg) {
	return call SlottedCollisionConfig.getCollisionWindowLength(msg);
}

/*
	Slotted Events
*/

tasklet_async event void SlottedRadioSend.ready() {
	return signal RadioSend.ready();
}

tasklet_async event void SlottedRadioSend.sendDone(error_t error) {
	return signal RadioSend.sendDone(error);
}

tasklet_async event bool SlottedRadioReceive.header(message_t* msg) {
	return signal RadioReceive.header(msg);
}


tasklet_async event message_t* SlottedRadioReceive.receive(message_t* msg) {
	return signal RadioReceive.receive(msg);
}


/*
	Random Commands
*/

tasklet_async command error_t RandomSubSend.send(message_t* msg) {
	return call SubSend.send(msg);
}

tasklet_async command bool RandomRadioAlarm.isFree() {
	return call RadioAlarm.isFree();
}

tasklet_async command void RandomRadioAlarm.wait(tradio_size timeout) {
	return call RadioAlarm.wait(timeout);
}

tasklet_async command void RandomRadioAlarm.cancel() {
	return call RadioAlarm.cancel();
}

async command tradio_size RandomRadioAlarm.getNow() {
	return call RadioAlarm.getNow();
}




/*
	Random Events
*/

tasklet_async event void RandomRadioSend.ready() {
	return signal RadioSend.ready();
}

tasklet_async event void RandomRadioSend.sendDone(error_t error) {
	return signal RadioSend.sendDone(error);
}

tasklet_async event bool RandomRadioReceive.header(message_t* msg) {
	return signal RadioReceive.header(msg);
}


tasklet_async event message_t* RandomRadioReceive.receive(message_t* msg) {
	return signal RadioReceive.receive(msg);
}




}

