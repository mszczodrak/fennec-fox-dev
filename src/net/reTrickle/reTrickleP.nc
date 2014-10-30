#include <Fennec.h>
#include "reTrickle.h"

generic module reTrickleP(process_t process) {
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

uint16_t delay;
uint8_t repeat;
bool busy = FALSE;

uint8_t receive_same_packet;
uint8_t suppress;

bool signal_send_done;
message_t packet;
void packet_payload_ptr;
uint8_t packet_len;
uint8_t packet_tx_repeat;

void send_message() {
	if (busy) {
		signal SubAMSend.sendDone(&packet, SUCCESS);
		return;
	}

	if (call SubAMSend.send(BROADCAST, &packet, packet_len) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		busy = TRUE;
	}
}

void make_copy(void *new_payload, uint8_t new_payload_len) {
	call Timer.startPeriodic(delay);
	packet_payload_ptr = call SubAMSend.getPayload(&packet, new_payload_len);
	packet_len = payload_len;
	memcpy(packet_payload_ptr, new_payload, new_payload_len);
	packet_tx_repeat = repeat;
	send_message();
}

bool same_packet(void *in_payload, uint_t in_len) {
	return ((in_len == payload_len) && !(memcmp(in_payload, packet_payload_ptr, in_len)));
}

command error_t SplitControl.start() {
	busy = FALSE;
	signal_send_done = FALSE;
	receive_same_packet = 0;

	packet_payload_ptr = call SubAMSend.getPayload(&packet, 10);

	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(SUPPRESS, &suppress, sizeof(suppress));

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	busy = FALSE;
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
	packet_tx_repeat--;
	if (receive_same_packet < suppress) {
		send_message();
	}
	receive_same_packet = 0;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	void *payload = call SubAMSend.getPayload(msg, len);
	signal_send_done = TRUE;
	if (same_packet(payload, len)) {
		printf("Already disseminating\n");
		return SUCCESS;
	}

	make_copy(payload, len);
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
	busy = FALSE;
	if (packet_tx_repeat <= 0) {
		call Timer.stop();
		if (signal_send_done) {
			signal Send.sendDone(msg, error);
			signal_send_done = FALSE;
		}
	}
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	if (same_packet(payload, len)) {
		receive_same_packet++;
		printf("Already received\n");
                return msg;
        }

	make_copy(payload, len);

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

event void Param.updated(uint8_t var_id) {

}


}
