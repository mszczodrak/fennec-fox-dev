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

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;

}

implementation {

uint16_t retry_delay;
uint8_t repeat;
bool busy = FALSE;
uint8_t pkt_len;
am_addr_t pkt_addr;
message_t *pkt_msg;
void *pkt_payload;
uint8_t receive_counter = 0;

command error_t SplitControl.start() {
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] rebroadcast SplitControl.start()\n", process);
#else

#endif
#endif
	busy = FALSE;
	pkt_payload = NULL;
	receive_counter = 0;
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%d] rebroadcast SplitControl.stop()\n", process);
#else

#endif
#endif
	busy = FALSE;
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

task void send_msg() {
	if (busy)
		return;

	busy = TRUE;

	if (pkt_msg == NULL) {
		signal SubAMSend.sendDone(pkt_msg, FAIL);
	}

	if (call SubAMSend.send(pkt_addr, pkt_msg, pkt_len) != SUCCESS) {
		signal SubAMSend.sendDone(pkt_msg, FAIL);
	}
}

event void Timer.fired() {
	if (!busy || (receive_counter <= SUPPRESS_REBROADCAST)) {
		post send_message();
	}

	receive_counter = 0;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(RETRY_DELAY, &retry_delay, sizeof(retry_delay));

	if (pkt_msg != NULL) {
		signal AMSend.sendDone(pkt_msg, EALREADY);
	}

	pkt_len = len + sizeof(nx_struct rebroadcast_header);
	pkt_addr = addr;
	pkt_msg = msg;
	pkt_payload = call SubAMSend.getPayload(pkt_msg, pkt_len);

	if (pkt_addr == TOS_NODE_ID) {
		signal AMSend.sendDone(pkt_msg, SUCCESS);
		signal SubReceive.receive(msg, 
			call AMSend.getPayload(pkt_msg, pkt_len), pkt_len);
		busy = FALSE;
		return SUCCESS;
	}

	receive_counter = 0;
	post send_msg();

	return SUCCESS;
}

command error_t AMSend.cancel(message_t* msg) {
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	return (call SubAMSend.maxPayloadLength() - 
		sizeof(nx_struct rebroadcast_header));
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] rebroadcast AMSend.getpayload( 0x%p, %u )\n", process, msg, len);
#else

#endif
#endif
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, 
				len + sizeof(nx_struct rebroadcast_header));
	return (void*) (ptr + sizeof(nx_struct rebroadcast_header));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	repeat--;
	busy = FALSE;
	if (repeat == 0) {
		pkt_msg = NULL;
		call Timer.stop();
		signal AMSend.sendDone(msg, error);
	} else {
		call Timer.startOneShot(retry_delay);
	}
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	receive_counter++;
	if (!memcmp(pkt_payload, payload, len)) {
		return msg;
	}
	
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] rebroadcast Receive.receive( 0x%p, 0x%p, %u )\n", process, msg, payload, len);
#else

#endif
#endif
	return signal Receive.receive(msg, 
			ptr + sizeof(nx_struct rebroadcast_header), 
			len - sizeof(nx_struct rebroadcast_header));
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;

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

event void Param.updated(uint8_t var_id, bool conflict) {

}


}
