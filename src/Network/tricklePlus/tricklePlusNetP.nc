/*
 *  tricklePlus network module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2013 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Network: tricklePlus Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 9/5/2013
 */

#include <Fennec.h>
#include "tricklePlusNet.h"

module tricklePlusNetP {
provides interface Mgmt;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface tricklePlusNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface TrickleTimer[uint16_t key];
}

implementation {

message_t data_msg;
uint8_t data_len;

bool tx_busy = FALSE;
message_t *app_data = NULL;
nxle_uint32_t seqno;

/* Trickle Plus - remember the content of the message */
void *app_payload = NULL;

#define DISSEMINATION_SEQNO_UNKNOWN 0

task void send_message() {
	nx_struct tricklePlus_net_header *header;
	dbg("Network", "tricklePlusNetP send_message");
	if (tx_busy == TRUE) {
		dbg("Network", "tricklePlusNetP send_message -> tx_busy == TRUE");
		return;
	}

	header = (nx_struct tricklePlus_net_header*)
		call MacAMSend.getPayload(&data_msg, data_len + sizeof(nx_struct tricklePlus_net_header));

	if (header == NULL) {
		dbg("Network", "tricklePlusNetP send_message -> header == NULL");
		return;
	}

	header->seq = seqno;

	if (call MacAMSend.send(BROADCAST, &data_msg, data_len) == SUCCESS) {
		tx_busy = TRUE;
		return;
	}
	dbg("Network", "tricklePlusNetP send_message MacAMSend.send(%d, 0x%1x, %d) != SUCCESS",
			BROADCAST, &data_msg, data_len + sizeof(nx_struct tricklePlus_net_header));
}


command error_t Mgmt.start() {
	dbg("Network", "tricklePlusNetP Mgmt.start()");
	tx_busy = FALSE;
	app_data = NULL;
	data_len = 0;
	seqno = DISSEMINATION_SEQNO_UNKNOWN;
	call TrickleTimer.start[TRICKLE_ID]();
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}


command error_t Mgmt.stop() {
	dbg("Network", "tricklePlusNetP Mgmt.stop()");
	call TrickleTimer.stop[TRICKLE_ID]();
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}


command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "tricklePlusNetP NetworkAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len + sizeof(nx_struct tricklePlus_net_header);
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
	dbg("Network", "tricklePlusNetP NetworkAMSend.cancel(0x%1x)", msg);
	return call MacAMSend.cancel(msg);
}


command uint8_t NetworkAMSend.maxPayloadLength() {
	dbg("Network", "tricklePlusNetP NetworkAMSend.maxPayloadLength()");
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct tricklePlus_net_header));
}


command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "tricklePlusNetP NetworkAMSend.getpayload(0x%1x, %d )", msg, len);
	ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct tricklePlus_net_header));

	/* Trickle Plus - memorize the content of the message */
	app_payload = (void*) (ptr + sizeof(nx_struct tricklePlus_net_header));

	return (void*) (ptr + sizeof(nx_struct tricklePlus_net_header));
}


event void MacAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "tricklePlusNetP NetworkAMSend.sendDone(0x%1x, %d )", msg, error);
	tx_busy = FALSE;
	if (app_data != NULL) {
		signal NetworkAMSend.sendDone(app_data, error);
		app_data = NULL;
	}
}


event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct tricklePlus_net_header *header = (nx_struct tricklePlus_net_header*) payload;
	uint8_t *ptr = (uint8_t*) payload;

	dbg("Network", "tricklePlusNetP receive_data(0x%1x, 0x%1x, %d )", msg, payload, len);

	if (seqno == DISSEMINATION_SEQNO_UNKNOWN &&
		header->seq != DISSEMINATION_SEQNO_UNKNOWN) {
		goto receive;
	}

	if (header->seq == DISSEMINATION_SEQNO_UNKNOWN &&
		seqno != DISSEMINATION_SEQNO_UNKNOWN) {
		call TrickleTimer.reset[TRICKLE_ID]();
		goto snoop;
	}

	/* Trickle Plus - check message content */
	if ((data_len != len) || !memcmp(payload, app_payload, len)) {
		goto alert;
	} 

	if ((int32_t)(header->seq - seqno) > 0) {
		goto receive;

	} else if ( (int32_t)(header->seq - seqno) == 0) {
		call TrickleTimer.incrementCounter[TRICKLE_ID]();
	} else {
		/* Trickle source code is not sure what to do about it */
		/* Immediate send */
		post send_message();
	}

snoop:
	return signal NetworkSnoop.receive(msg, 
		ptr + sizeof(nx_struct tricklePlus_net_header), 
		len - sizeof(nx_struct tricklePlus_net_header));

receive:
	dbg("Network", "tricklePlusNetP NetworkReceive.receive(0x%1x, 0x%1x, %d )", msg, 
		ptr + sizeof(nx_struct tricklePlus_net_header), 
		len - sizeof(nx_struct tricklePlus_net_header));

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len;
	seqno = header->seq;
	call TrickleTimer.reset[ TRICKLE_ID ]();

/* Trickle Plus - alert app when content disagrees */
alert:
	return signal NetworkReceive.receive(msg, 
		ptr + sizeof(nx_struct tricklePlus_net_header), 
		len - sizeof(nx_struct tricklePlus_net_header));
}


event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "tricklePlusNetP NetworkSnoop.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct tricklePlus_net_header), 
			len - sizeof(nx_struct tricklePlus_net_header));
	return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct tricklePlus_net_header), 
			len - sizeof(nx_struct tricklePlus_net_header));
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


default command error_t TrickleTimer.start[uint16_t key]() { return FAIL; }
default command void TrickleTimer.stop[uint16_t key]() { }
default command void TrickleTimer.reset[uint16_t key]() { }
default command void TrickleTimer.incrementCounter[uint16_t key]() { }

}
