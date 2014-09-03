/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox Trickle  Protocol adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/18/2010
  */


#include <Fennec.h>
#include "trickle.h"

generic module trickleP(process_t process) {
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

uses interface TrickleTimer[uint16_t key];
provides interface TrickleTimerParams;
}

implementation {

message_t data_msg;
uint8_t data_len;

bool tx_busy = FALSE;
message_t *app_data = NULL;
nx_uint32_t seqno;

task void send_message() {
	nx_struct trickle_net_header *header;
	dbg("", "trickleP send_message");
	if (tx_busy == TRUE) {
		dbg("", "trickleP send_message -> tx_busy == TRUE");
		return;
	}

	header = (nx_struct trickle_net_header*)
		call SubAMSend.getPayload(&data_msg, data_len + sizeof(nx_struct trickle_net_header));

	if (header == NULL) {
		dbg("", "trickleP send_message -> header == NULL");
		return;
	}

	header->seq = seqno;

	if (call SubAMSend.send(BROADCAST, &data_msg, data_len) == SUCCESS) {
		tx_busy = TRUE;
		return;
	}
	dbg("", "trickleP send_message SubAMSend.send(%d, 0x%1x, %d) != SUCCESS",
			BROADCAST, &data_msg, data_len + sizeof(nx_struct trickle_net_header));
}


command error_t SplitControl.start() {
	dbg("", "trickleP SplitControl.start()");
	tx_busy = FALSE;
	app_data = NULL;
	data_len = 0;
	seqno = 0;
	call TrickleTimer.start[TRICKLE_ID]();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("", "trickleP SplitControl.stop()");
	call TrickleTimer.stop[TRICKLE_ID]();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("", "trickleP AMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len + sizeof(nx_struct trickle_net_header);
	app_data = msg;

	/* Increment the counter and append the local node ID. */
	seqno = seqno >> 16;
	seqno++;
	if ( seqno == 0 ) { seqno++; }
	seqno = seqno << 16;
	seqno += TOS_NODE_ID;

	call TrickleTimer.reset[TRICKLE_ID]();
	post send_message();
	return SUCCESS;
}


command error_t AMSend.cancel(message_t* msg) {
	dbg("", "trickleP AMSend.cancel(0x%1x)", msg);
	return call SubAMSend.cancel(msg);
}


command uint8_t AMSend.maxPayloadLength() {
	dbg("", "trickleP AMSend.maxPayloadLength()");
	return (call SubAMSend.maxPayloadLength() - 
		sizeof(nx_struct trickle_net_header));
}


command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("", "trickleP AMSend.getpayload(0x%1x, %d )", msg, len);
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, 
				len + sizeof(nx_struct trickle_net_header));
	return (void*) (ptr + sizeof(nx_struct trickle_net_header));
}


event void SubAMSend.sendDone(message_t *msg, error_t error) {
	dbg("", "trickleP AMSend.sendDone(0x%1x, %d )", msg, error);
	tx_busy = FALSE;
	if (app_data != NULL) {
		signal AMSend.sendDone(app_data, error);
		app_data = NULL;
	}
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*) payload;
	uint8_t *ptr = (uint8_t*) payload;

	dbg("", "trickleP receive_data(0x%1x, 0x%1x, %d )", msg, payload, len);

	if ((int32_t)(header->seq - seqno) < 0) {
		call TrickleTimer.reset[TRICKLE_ID]();
		return msg;

	}

	if ( (int32_t)(header->seq - seqno) == 0) {
		call TrickleTimer.incrementCounter[TRICKLE_ID]();
		return signal Snoop.receive(msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));

	}

	dbg("", "trickleP Receive.receive(0x%1x, 0x%1x, %d )", msg, 
		ptr + sizeof(nx_struct trickle_net_header), 
		len - sizeof(nx_struct trickle_net_header));

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len;
	seqno = header->seq;
	call TrickleTimer.reset[ TRICKLE_ID ]();

	return signal Receive.receive(msg, 
		ptr + sizeof(nx_struct trickle_net_header), 
		len - sizeof(nx_struct trickle_net_header));
}


event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("", "trickleP Snoop.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));
	return signal Snoop.receive(msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));
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

event void TrickleTimer.fired[ uint16_t key ]() {
	post send_message();
}

command uint16_t TrickleTimerParams.get_low() {
	uint16_t low;
	call Param.get(LOW, &low, sizeof(low));
	return low;
}

command error_t TrickleTimerParams.set_low(uint16_t new_low) {
	uint16_t low = new_low;
	return call Param.set(LOW, &low, sizeof(low));
}

command uint16_t TrickleTimerParams.get_high() {
	uint16_t high;
	call Param.get(HIGH, &high, sizeof(high));
	return high;
}

command error_t TrickleTimerParams.set_high(uint16_t new_high) {
	uint16_t high = new_high;
	return call Param.set(HIGH, &high, sizeof(high));
}

command uint8_t TrickleTimerParams.get_k() {
	uint8_t k;
	call Param.get(K, &k, sizeof(k));
	return k;
}

command error_t TrickleTimerParams.set_k(uint8_t new_k) {
	uint8_t k = new_k;
	return call Param.set(K, &k, sizeof(k));
}

command uint8_t TrickleTimerParams.get_scale() {
	uint8_t scale;
	call Param.get(SCALE, &scale, sizeof(scale));
	return scale;
}

command error_t TrickleTimerParams.set_scale(uint8_t new_scale) {
	uint8_t scale = new_scale;
	return call Param.set(SCALE, &scale, sizeof(scale));
}

event void RadioChannel.setChannelDone() {
}

default command error_t TrickleTimer.start[uint16_t key]() { return FAIL; }
default command void TrickleTimer.stop[uint16_t key]() { }
default command void TrickleTimer.reset[uint16_t key]() { }
default command void TrickleTimer.incrementCounter[uint16_t key]() { }

}
