#include <Fennec.h>
#include "ctp.h"
#include "Ctp.h"

generic module ctpP(process_t process) {
/* All layer interfaces */
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface ctpParams;

/*
uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
*/
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


}
