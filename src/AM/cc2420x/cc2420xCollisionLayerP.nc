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

/* wire to Random */
uses interface RadioSend as RandomRadioSend;
uses interface RadioReceive as RandomRadioReceive;

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


/*
	Slotted Events
*/


/*
	Random Commands
*/


/*
	Random Events
*/




}

