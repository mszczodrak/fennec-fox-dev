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
  * Fennec Fox Trickle Network Protocol adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/18/2010
  */


#include <Fennec.h>
#include "trickle.h"

generic module trickleP(process_t process) {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface trickleParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
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
	dbg("Network", "trickleP send_message");
	if (tx_busy == TRUE) {
		dbg("Network", "trickleP send_message -> tx_busy == TRUE");
		return;
	}

	header = (nx_struct trickle_net_header*)
		call MacAMSend.getPayload(&data_msg, data_len + sizeof(nx_struct trickle_net_header));

	if (header == NULL) {
		dbg("Network", "trickleP send_message -> header == NULL");
		return;
	}

	header->seq = seqno;

	if (call MacAMSend.send(BROADCAST, &data_msg, data_len) == SUCCESS) {
		tx_busy = TRUE;
		return;
	}
	dbg("Network", "trickleP send_message MacAMSend.send(%d, 0x%1x, %d) != SUCCESS",
			BROADCAST, &data_msg, data_len + sizeof(nx_struct trickle_net_header));
}


command error_t SplitControl.start() {
	dbg("Network", "trickleP SplitControl.start()");
	tx_busy = FALSE;
	app_data = NULL;
	data_len = 0;
	seqno = 0;
	call TrickleTimer.start[TRICKLE_ID]();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("Network", "trickleP SplitControl.stop()");
	call TrickleTimer.stop[TRICKLE_ID]();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "trickleP NetworkAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

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


command error_t NetworkAMSend.cancel(message_t* msg) {
	dbg("Network", "trickleP NetworkAMSend.cancel(0x%1x)", msg);
	return call MacAMSend.cancel(msg);
}


command uint8_t NetworkAMSend.maxPayloadLength() {
	dbg("Network", "trickleP NetworkAMSend.maxPayloadLength()");
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct trickle_net_header));
}


command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "trickleP NetworkAMSend.getpayload(0x%1x, %d )", msg, len);
	ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct trickle_net_header));
	return (void*) (ptr + sizeof(nx_struct trickle_net_header));
}


event void MacAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "trickleP NetworkAMSend.sendDone(0x%1x, %d )", msg, error);
	tx_busy = FALSE;
	if (app_data != NULL) {
		signal NetworkAMSend.sendDone(app_data, error);
		app_data = NULL;
	}
}


event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*) payload;
	uint8_t *ptr = (uint8_t*) payload;

	dbg("Network", "trickleP receive_data(0x%1x, 0x%1x, %d )", msg, payload, len);

	if ((int32_t)(header->seq - seqno) < 0) {
		call TrickleTimer.reset[TRICKLE_ID]();
		return msg;

	}

	if ( (int32_t)(header->seq - seqno) == 0) {
		call TrickleTimer.incrementCounter[TRICKLE_ID]();
		return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));

	}

	dbg("Network", "trickleP NetworkReceive.receive(0x%1x, 0x%1x, %d )", msg, 
		ptr + sizeof(nx_struct trickle_net_header), 
		len - sizeof(nx_struct trickle_net_header));

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len;
	seqno = header->seq;
	call TrickleTimer.reset[ TRICKLE_ID ]();

	return signal NetworkReceive.receive(msg, 
		ptr + sizeof(nx_struct trickle_net_header), 
		len - sizeof(nx_struct trickle_net_header));
}


event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "trickleP NetworkSnoop.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));
	return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));
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

event void TrickleTimer.fired[ uint16_t key ]() {
	post send_message();
}

command uint16_t TrickleTimerParams.get_low() {
	return call trickleParams.get_low();
}

command error_t TrickleTimerParams.set_low(uint16_t new_low) {
	return call trickleParams.set_low(new_low);
}

command uint16_t TrickleTimerParams.get_high() {
	return call trickleParams.get_high();
}

command error_t TrickleTimerParams.set_high(uint16_t new_high) {
	return call trickleParams.set_high(new_high);
}

command uint8_t TrickleTimerParams.get_k() {
	return call trickleParams.get_k();
}

command error_t TrickleTimerParams.set_k(uint8_t new_k) {
	return call trickleParams.set_k(new_k);
}

command uint8_t TrickleTimerParams.get_scale() {
	return call trickleParams.get_scale();
}

command error_t TrickleTimerParams.set_scale(uint8_t new_scale) {
	return call trickleParams.set_scale(new_scale);
}

event void RadioChannel.setChannelDone() {
}

default command error_t TrickleTimer.start[uint16_t key]() { return FAIL; }
default command void TrickleTimer.stop[uint16_t key]() { }
default command void TrickleTimer.reset[uint16_t key]() { }
default command void TrickleTimer.incrementCounter[uint16_t key]() { }

}
