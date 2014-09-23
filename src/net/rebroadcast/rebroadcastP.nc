#include <Fennec.h>
#include "rebroadcast.h"

generic module rebroadcastP(process_t process) {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface Leds;
uses interface Timer<TMilli>;
}

implementation {

/* Parameters:
uint8_t repeat = 1,
float delay = 1
*/


uint8_t retry;
uint16_t retry_delay;
uint8_t repeat;
bool busy = FALSE;
uint8_t pkt_len;
am_addr_t pkt_addr;
message_t *pkt_msg;
error_t pkt_err;

command error_t SplitControl.start() {
	dbg("", "[%d] rebroadcast SplitControl.start()", process);
	busy = FALSE;
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("", "[%d] rebroadcast SplitControl.stop()", process);
	busy = FALSE;
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
	signal SubAMSend.sendDone(pkt_msg, pkt_err);
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	nx_struct rebroadcast_header *hdr;

	dbg("", "[%d] rebroadcast AMSend.send(%d, 0x%1x, %d )",
		process, addr, msg, len);

	if (busy)
		return EBUSY;

	busy = TRUE;

	call Param.get(RETRY, &retry, sizeof(retry));
	call Param.get(REPEAT, &repeat, sizeof(repeat));

	pkt_len = len + sizeof(nx_struct rebroadcast_header);
	pkt_addr = addr;
	pkt_msg = msg;

	hdr = (nx_struct rebroadcast_header*) call SubAMSend.getPayload(pkt_msg, pkt_len);
	hdr->repeat = repeat;

	if (pkt_addr == TOS_NODE_ID) {
		dbg("", "[%d] rebroadcast AMSend.sendDone(0x%1x, %d )", process, pkt_msg, SUCCESS);
		hdr->repeat = 0;
		signal AMSend.sendDone(pkt_msg, SUCCESS);
		signal SubReceive.receive(msg, 
			call AMSend.getPayload(pkt_msg, pkt_len), pkt_len);
		busy = FALSE;
		return SUCCESS;
	}

	pkt_err = call SubAMSend.send(pkt_addr, pkt_msg, pkt_len);

	if (pkt_err != SUCCESS) {
		call Param.get(RETRY_DELAY, &retry_delay, sizeof(retry_delay));
		call Timer.startOneShot(retry_delay);
	}

	return SUCCESS;
}

command error_t AMSend.cancel(message_t* msg) {
	dbg("", "[%d] rebroadcast AMSend.cancel(0x%1x)", process, msg);
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	dbg("", "[%d] rebroadcast AMSend.maxPayloadLength()", process);
	return (call SubAMSend.maxPayloadLength() - 
		sizeof(nx_struct rebroadcast_header));
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("", "[%d] rebroadcast AMSend.getpayload(0x%1x, %d )", process, msg, len);
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, 
				len + sizeof(nx_struct rebroadcast_header));
	return (void*) (ptr + sizeof(nx_struct rebroadcast_header));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	nx_struct rebroadcast_header *hdr;

	dbg("", "[%d] rebroadcast AMSend.sendDone(0x%1x, %d )", process, msg, error);

	hdr = (nx_struct rebroadcast_header*) call SubAMSend.getPayload(msg, pkt_len);

	if (error != SUCCESS) {
		retry--;
	} else {
		hdr->repeat--;
	}

	if ((retry == 0) || (hdr->repeat == 0)) {
		signal AMSend.sendDone(msg, error);
		busy = FALSE;
		return;
	}

	pkt_err = call SubAMSend.send(pkt_addr, msg, pkt_len);

	if (pkt_err != SUCCESS) {
		call Param.get(RETRY_DELAY, &retry_delay, sizeof(retry_delay));
		call Timer.startOneShot(retry_delay);
	}
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;

	dbg("", "[%d] rebroadcast Receive.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
	return signal Receive.receive(msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("", "[%d] rebroadcast Snoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
	return signal Snoop.receive(msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
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

event void RadioChannel.setChannelDone() {
}

event void Param.updated(uint8_t var_id) {

}


}
