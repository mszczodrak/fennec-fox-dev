#include <Fennec.h>
#include "ftsp.h"

generic module ftspP(process_t process) {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

uses interface Param;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
}

implementation {

command error_t SplitControl.start() {
	dbg("Network", "[%d] ftsp SplitControl.start()", process);
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Network", "[%d] ftsp SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "[%d] ftsp NetworkAMSend.send(%d, 0x%1x, %d )",
		process, addr, msg, len);

	if ((addr == TOS_NODE_ID)) {
		dbg("Network", "[%d] ftsp NetworkAMSend.sendDone(0x%1x, %d )", process, msg, SUCCESS);
		signal AMSend.sendDone(msg, SUCCESS);
		signal SubReceive.receive(msg, 
		call AMSend.getPayload(msg, len + 
				sizeof(nx_struct ftsp_header)), 
		len + sizeof(nx_struct ftsp_header));
		return SUCCESS;
	}

	return call SubAMSend.send(addr, msg, len + 
		sizeof(nx_struct ftsp_header));
}

command error_t AMSend.cancel(message_t* msg) {
	dbg("Network", "[%d] ftsp NetworkAMSend.cancel(0x%1x)", process, msg);
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	dbg("Network", "[%d] ftsp NetworkAMSend.maxPayloadLength()", process);
	return (call SubAMSend.maxPayloadLength() - 
		sizeof(nx_struct ftsp_header));
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "[%d] ftsp NetworkAMSend.getpayload(0x%1x, %d )", process, msg, len);
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, 
				len + sizeof(nx_struct ftsp_header));
	return (void*) (ptr + sizeof(nx_struct ftsp_header));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "[%d] ftsp NetworkAMSend.sendDone(0x%1x, %d )", process, msg, error);
	signal AMSend.sendDone(msg, error);
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] ftsp NetworkReceive.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct ftsp_header), 
			len - sizeof(nx_struct ftsp_header));
	return signal Receive.receive(msg, 
			ptr + sizeof(nx_struct ftsp_header), 
			len - sizeof(nx_struct ftsp_header));
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] ftsp NetworkSnoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct ftsp_header), 
			len - sizeof(nx_struct ftsp_header));
	return signal Snoop.receive(msg, 
			ptr + sizeof(nx_struct ftsp_header), 
			len - sizeof(nx_struct ftsp_header));
}

command am_addr_t AMPacket.address() {
	return call SubAMPacket.address();
}

command am_addr_t AMPacket.destination(message_t* amsg) {
	return call SubAMPacket.destination(amsg);
}

command am_addr_t AMPacket.source(message_t* amsg) {
	return call SubAMPacket.source(amsg);
}

command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setDestination(amsg, addr);
}

command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setSource(amsg, addr);
}

command bool AMPacket.isForMe(message_t* amsg) {
	return call SubAMPacket.isForMe(amsg);
}

command am_id_t AMPacket.type(message_t* amsg) {
	return call SubAMPacket.type(amsg);
}

command void AMPacket.setType(message_t* amsg, am_id_t t) {
	return call SubAMPacket.setType(amsg, t);
}

command am_group_t AMPacket.group(message_t* amsg) {
	return call SubAMPacket.group(amsg);
}

command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call SubAMPacket.setGroup(amsg, grp);
}

command am_group_t AMPacket.localGroup() {
	return call SubAMPacket.localGroup();
}

command void Packet.clear(message_t* msg) {
	return call SubPacket.clear(msg);
}

command uint8_t Packet.payloadLength(message_t* msg) {
	return call SubPacket.payloadLength(msg);
}

command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
	return call SubPacket.setPayloadLength(msg, len);
}

command uint8_t Packet.maxPayloadLength() {
	return call SubPacket.maxPayloadLength();
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	return call SubPacket.getPayload(msg, len);
}

async command error_t PacketAcknowledgements.requestAck( message_t* msg ) {
	return call SubPacketAcknowledgements.requestAck(msg);
}

async command error_t PacketAcknowledgements.noAck( message_t* msg ) {
	return call SubPacketAcknowledgements.noAck(msg);
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return call SubPacketAcknowledgements.wasAcked(msg);
}

event void Param.updated(uint8_t var_id) {

}

event void RadioChannel.setChannelDone() {

}

}
