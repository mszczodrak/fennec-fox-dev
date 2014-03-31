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

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
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

ctp_routing_header_t* getHeader(message_t* ONE m) {
	return (ctp_routing_header_t*)call MacAMSend.getPayload(m, call MacAMSend.maxPayloadLength());
}

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



event void MacAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "[%d] ctp NetworkAMSend.sendDone(0x%1x, %d )", process, msg, error);
	signal NetworkAMSend.sendDone(msg, error);
}

event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] ctp NetworkReceive.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct ctp_header), 
			len - sizeof(nx_struct ctp_header));
	return signal NetworkReceive.receive(msg, 
			ptr + sizeof(nx_struct ctp_header), 
			len - sizeof(nx_struct ctp_header));
}

event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] ctp NetworkSnoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct ctp_header), 
			len - sizeof(nx_struct ctp_header));
	return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct ctp_header), 
			len - sizeof(nx_struct ctp_header));
}

command am_addr_t NetworkAMPacket.address() {
	return call MacAMPacket.address();
}

command am_addr_t NetworkAMPacket.destination(message_t* amsg) {
	return call MacAMPacket.destination(amsg);
}

command am_addr_t NetworkAMPacket.source(message_t* amsg) {
	return call MacAMPacket.source(amsg);
}

command void NetworkAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setDestination(amsg, addr);
}

command void NetworkAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setSource(amsg, addr);
}

command bool NetworkAMPacket.isForMe(message_t* amsg) {
	return call MacAMPacket.isForMe(amsg);
}

command am_id_t NetworkAMPacket.type(message_t* amsg) {
	return call MacAMPacket.type(amsg);
}

command void NetworkAMPacket.setType(message_t* amsg, am_id_t t) {
	return call MacAMPacket.setType(amsg, t);
}

command am_group_t NetworkAMPacket.group(message_t* amsg) {
	return call MacAMPacket.group(amsg);
}

command void NetworkAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call MacAMPacket.setGroup(amsg, grp);
}

command am_group_t NetworkAMPacket.localGroup() {
	return call MacAMPacket.localGroup();
}

command void NetworkPacket.clear(message_t* msg) {
	return call MacPacket.clear(msg);
}

command uint8_t NetworkPacket.payloadLength(message_t* msg) {
	return call MacPacket.payloadLength(msg);
}

command void NetworkPacket.setPayloadLength(message_t* msg, uint8_t len) {
	return call MacPacket.setPayloadLength(msg, len);
}

command uint8_t NetworkPacket.maxPayloadLength() {
	return call MacPacket.maxPayloadLength();
}

command void* NetworkPacket.getPayload(message_t* msg, uint8_t len) {
	return call MacPacket.getPayload(msg, len);
}

async command error_t NetworkPacketAcknowledgements.requestAck( message_t* msg ) {
	return call MacPacketAcknowledgements.requestAck(msg);
}

async command error_t NetworkPacketAcknowledgements.noAck( message_t* msg ) {
	return call MacPacketAcknowledgements.noAck(msg);
}

async command bool NetworkPacketAcknowledgements.wasAcked(message_t* msg) {
	return call MacPacketAcknowledgements.wasAcked(msg);
}

event void RadioChannel.setChannelDone() {
}


}
