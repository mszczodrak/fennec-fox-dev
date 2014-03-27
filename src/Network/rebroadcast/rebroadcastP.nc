#include <Fennec.h>
#include "rebroadcast.h"

generic module rebroadcastP(process_t process) {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface rebroadcastParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
}

implementation {

/* Parameters:
uint8_t repeat = 1,
uint8_t delay = 1
*/

command error_t SplitControl.start() {
	dbg("Network", "[%d] rebroadcast SplitControl.start()", process);
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Network", "[%d] rebroadcast SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "[%d] rebroadcast NetworkAMSend.send(%d, 0x%1x, %d )",
		process, addr, msg, len);

	if ((addr == TOS_NODE_ID)) {
		dbg("Network", "[%d] rebroadcast NetworkAMSend.sendDone(0x%1x, %d )", process, msg, SUCCESS);
		signal NetworkAMSend.sendDone(msg, SUCCESS);
		signal MacReceive.receive(msg, 
		call NetworkAMSend.getPayload(msg, len + 
				sizeof(nx_struct rebroadcast_header)), 
		len + sizeof(nx_struct rebroadcast_header));
		return SUCCESS;
	}

	return call MacAMSend.send(addr, msg, len + 
		sizeof(nx_struct rebroadcast_header));
}

command error_t NetworkAMSend.cancel(message_t* msg) {
	dbg("Network", "[%d] rebroadcast NetworkAMSend.cancel(0x%1x)", process, msg);
	return call MacAMSend.cancel(msg);
}

command uint8_t NetworkAMSend.maxPayloadLength() {
	dbg("Network", "[%d] rebroadcast NetworkAMSend.maxPayloadLength()", process);
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct rebroadcast_header));
}

command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "[%d] rebroadcast NetworkAMSend.getpayload(0x%1x, %d )", process, msg, len);
	ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct rebroadcast_header));
	return (void*) (ptr + sizeof(nx_struct rebroadcast_header));
}

event void MacAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "[%d] rebroadcast NetworkAMSend.sendDone(0x%1x, %d )", process, msg, error);
	signal NetworkAMSend.sendDone(msg, error);
}

event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] rebroadcast NetworkReceive.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
	return signal NetworkReceive.receive(msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
}

event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "[%d] rebroadcast NetworkSnoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
	return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
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

}
