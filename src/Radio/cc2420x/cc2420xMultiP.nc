
#include "CC2420XDriverLayer.h"

module cc2420xMultiP {
provides interface SplitControl[process_t process_id];
provides interface RadioReceive[process_t process_id];
provides interface RadioSend[process_t process_id];
provides interface RadioState[process_t process_id];

uses interface cc2420xParams[process_t process_id];
uses interface RadioReceive as SubRadioReceive;
uses interface RadioSend as SubRadioSend;
uses interface RadioState as SubRadioState;
uses interface CC2420XDriverConfig;
}

implementation {

process_t sp_proc = UNKNOWN;

cc2420x_header_t* getHeader(message_t* msg) {
	return ((void*)msg) + call CC2420XDriverConfig.headerLength(msg);
}

task void startDone() {
	signal SplitControl.startDone[sp_proc](SUCCESS);
}


task void stopDone() {
	signal SplitControl.stopDone[sp_proc](SUCCESS);
}

command error_t SplitControl.start[process_t process_id]() {
	sp_proc = process_id;
	post startDone();
	return SUCCESS;
}

command error_t SplitControl.stop[process_t process_id]() {
	sp_proc = process_id;
	post stopDone();
	return SUCCESS;
}


async event bool SubRadioReceive.header(message_t* msg) {

}

async event message_t* SubRadioReceive.receive(message_t* msg) {

}

tasklet_async command error_t RadioSend.send[process_t process_id](message_t* msg) {
//	return call SubRadioSend.send(msg);
}

tasklet_async event void SubRadioSend.sendDone(error_t error) {
//	signal RadioSend.sendDone(error);
}

tasklet_async event void SubRadioSend.ready() {
//	signal RadioSend.ready();
//
}

tasklet_async command error_t RadioState.turnOff[process_t process_id]() {

}

tasklet_async command error_t RadioState.standby[process_t process_id]() {

}

tasklet_async command error_t RadioState.turnOn[process_t process_id]() {

}

tasklet_async command error_t RadioState.setChannel[process_t process_id](uint8_t channel) {

}

tasklet_async command uint8_t RadioState.getChannel[process_t process_id]() {

}

tasklet_async event void SubRadioState.done() {

}


default event void SplitControl.startDone[process_t process_id](error_t error) {}
default event void SplitControl.stopDone[process_t process_id](error_t error) {}

default async event bool RadioReceive.header[process_t process_id](message_t *msg) { return FALSE; }
default async event message_t* RadioReceive.receive[process_t process_id](message_t *msg) { return msg; }

default tasklet_async event void RadioSend.sendDone[process_t process_id](error_t error) {}
default tasklet_async event void RadioSend.ready[process_t process_id]() {}

default tasklet_async event void RadioState.done[process_t process_id]() {}

}
