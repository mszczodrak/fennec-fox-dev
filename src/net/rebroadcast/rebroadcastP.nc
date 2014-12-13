#include <Fennec.h>
#include "rebroadcast.h"

generic module rebroadcastP(process_t process) @safe() {
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
uses interface Random;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;

}

implementation {

uint16_t retry_delay;
uint8_t repeat;
bool busy = FALSE;
uint8_t pkt_len;
am_addr_t pkt_addr;
norace message_t *pkt_msg;
norace void *pkt_payload;
uint8_t receive_counter = 0;
uint8_t broadcast_repeat = 0;

command error_t SplitControl.start() {
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] rebroadcast SplitControl.start()\n", process);
#else

#endif
#endif
	busy = FALSE;
	repeat = 0;
	pkt_payload = NULL;
	receive_counter = 0;
	broadcast_repeat = 0;

	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(RETRY_DELAY, &retry_delay, sizeof(retry_delay));

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
	broadcast_repeat = 0;
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

task void send_message() {
	if (pkt_msg == NULL) {
		signal SubAMSend.sendDone(pkt_msg, FAIL);
		return;
	}

	if (busy)
		return;

	busy = TRUE;

	if (call SubAMSend.send(pkt_addr, pkt_msg, pkt_len) != SUCCESS) {
		signal SubAMSend.sendDone(pkt_msg, FAIL);
	}
}

event void Timer.fired() {
	if (broadcast_repeat == 0) {
		call Timer.stop();
	} else {
		if (!busy || (receive_counter <= SUPPRESS_REBROADCAST)) {
			post send_message();
		}
		call Timer.startPeriodic((retry_delay / 2) + call Random.rand16() % retry_delay);
	}
	receive_counter = 0;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	pkt_len = len;
	pkt_addr = addr;
	pkt_msg = msg;
	pkt_payload = call SubAMSend.getPayload(pkt_msg, pkt_len);
	broadcast_repeat = repeat;

	if (pkt_payload == NULL) {
		return FAIL;
	}

	if (pkt_addr == TOS_NODE_ID) {
		signal AMSend.sendDone(pkt_msg, SUCCESS);
		signal SubReceive.receive(msg, 
			call AMSend.getPayload(msg, pkt_len), pkt_len);
		busy = FALSE;
		return SUCCESS;
	}

	receive_counter = 0;
	post send_message();
	call Timer.startPeriodic((retry_delay / 2) + call Random.rand16() % retry_delay);

	return SUCCESS;
}

command error_t AMSend.cancel(message_t* msg) {
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	return call SubAMSend.maxPayloadLength();
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	return call SubAMSend.getPayload(msg, len);
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	if (broadcast_repeat == repeat) {
		signal AMSend.sendDone(msg, error);
	}

	busy = FALSE;
	broadcast_repeat--;

	if (broadcast_repeat > 0) {
		call Timer.startPeriodic((retry_delay / 2) + call Random.rand16() % retry_delay);
	}
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	if ((pkt_payload != NULL) && (!memcmp(pkt_payload, payload, len))) {
		receive_counter++;
		return msg;
	}
	
	return signal Receive.receive(msg, payload, len);
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return signal Snoop.receive(msg, payload, len);
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
