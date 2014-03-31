#include <Fennec.h>
#include "ctp.h"
#include "Ctp.h"

generic module ctpP(process_t process) {
/* All layer interfaces */
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;

uses interface ctpParams;

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

command error_t SplitControl.start() {
	if (call ctpParams.get_root() == TOS_NODE_ID) {
		call LowPowerListening.setLocalWakeupInterval(0);
		call RootControl.setRoot();
	}
	dbg("Network", "[%d] ctp SplitControl.start()", process);
	signal SplitControl.startDone(SUCCESS);
	signal FakeRadioControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Network", "[%d] ctp SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	signal FakeRadioControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t FakeRadioControl.start() { return SUCCESS; }
command error_t FakeRadioControl.stop() { return SUCCESS; }

command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	return call CtpSend.send(msg, len);
}

command error_t NetworkAMSend.cancel(message_t* msg) {
	return call CtpSend.cancel(msg);
}

command uint8_t NetworkAMSend.maxPayloadLength() {
	return call CtpSend.maxPayloadLength();
}

command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	return call CtpSend.getPayload(msg, len);
}

event void CtpSend.sendDone(message_t *msg, error_t error) {
	signal NetworkAMSend.sendDone(msg, error);
}

event void RadioChannel.setChannelDone() {
}

event message_t* CtpReceive.receive(message_t* msg, void* payload, uint8_t len) {
	return signal NetworkReceive.receive(msg, payload, len);
}

event message_t* CtpSnoop.receive(message_t* msg, void* payload, uint8_t len) {
	return signal NetworkSnoop.receive(msg, payload, len);
}

}
