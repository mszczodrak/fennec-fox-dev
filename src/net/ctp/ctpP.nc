#include <Fennec.h>
#include "ctp.h"
#include "Ctp.h"

generic module ctpP(process_t process) {
/* All layer interfaces */
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;

uses interface Param;

uses interface LowPowerListening;
uses interface RadioChannel;

/* Wiring to CTP */

provides interface SplitControl as FakeRadioControl;

uses interface StdControl as RoutingControl;
uses interface RootControl;
uses interface CollectionPacket;
uses interface CtpInfo;
uses interface CtpCongestion;
uses interface Send as CtpSend;
uses interface Receive as CtpReceive;
uses interface Receive as CtpSnoop;
uses interface Packet;

}

implementation {

uint16_t root;

command error_t SplitControl.start() {
	call RoutingControl.start();
	call Param.get(ROOT, &root, sizeof(root));
	if (root == TOS_NODE_ID) {
		call LowPowerListening.setLocalWakeupInterval(0);
		call RootControl.setRoot();
	}
	dbg("", "[%d] ctp SplitControl.start()", process);
	signal SplitControl.startDone(SUCCESS);
	signal FakeRadioControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	if (root == TOS_NODE_ID) {
		call RootControl.unsetRoot();
	}
	call RoutingControl.stop();
	dbg("", "[%d] ctp SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	signal FakeRadioControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t FakeRadioControl.start() { return SUCCESS; }
command error_t FakeRadioControl.stop() { return SUCCESS; }

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	return call CtpSend.send(msg, len);
}

command error_t AMSend.cancel(message_t* msg) {
	return call CtpSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	return call CtpSend.maxPayloadLength();
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	return call CtpSend.getPayload(msg, len);
}

event void CtpSend.sendDone(message_t *msg, error_t error) {
	signal AMSend.sendDone(msg, error);
}

event void RadioChannel.setChannelDone() {
}

event message_t* CtpReceive.receive(message_t* msg, void* payload, uint8_t len) {
	return signal Receive.receive(msg, payload, len);
}

event message_t* CtpSnoop.receive(message_t* msg, void* payload, uint8_t len) {
	return signal Snoop.receive(msg, payload, len);
}

}
