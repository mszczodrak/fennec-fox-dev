/*
 *  trickle network module for Fennec Fox platform.
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
 * Network: trickle Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 9/5/2013
 */

#include <Fennec.h>
#include "trickleNet.h"

module trickleNetP {
provides interface Mgmt;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface trickleNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface TrickleTimer[uint16_t key];

}

implementation {

message_t probe_msg;
message_t data_msg;
uint8_t data_len;
bool tx_busy = FALSE;
nxle_uint32_t seqno;

#define DISSEMINATION_SEQNO_UNKNOWN 0


error_t send_message(message_t* msg, uint8_t len, uint8_t type) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*)
		call MacAMSend.getPayload(msg, len + sizeof(nx_struct trickle_net_header));

	if ((tx_busy == TRUE) || (header == NULL) || (seqno == DISSEMINATION_SEQNO_UNKNOWN)) {
		return FAIL;
	}
	header->flags = type;
	header->seq = seqno;

	if (call MacAMSend.send(BROADCAST, msg, len + sizeof(nx_struct trickle_net_header)) == SUCCESS) {
		tx_busy = TRUE;
		return SUCCESS;
	}
	return FAIL;
}


command error_t Mgmt.start() {
	dbg("Network", "trickleNetP Mgmt.start()");
	tx_busy = FALSE;
	seqno = DISSEMINATION_SEQNO_UNKNOWN;
	call TrickleTimer.start[TRICKLE_ID]();
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}


command error_t Mgmt.stop() {
	dbg("Network", "trickleNetP Mgmt.stop()");
	call TrickleTimer.stop[TRICKLE_ID]();
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}


command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "trickleNetP NetworkAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	memcpy(&data_msg, msg, sizeof(message_t));
	data_len = len;

	/* Increment the counter and append the local node ID. */
	seqno = seqno >> 16;
	seqno++;
	if ( seqno == 0 ) { seqno++; }
	seqno = seqno << 16;
	seqno += TOS_NODE_ID;

	call TrickleTimer.reset[TRICKLE_ID]();
	return send_message(&data_msg, len, TRICKLE_DATA);
}


command error_t NetworkAMSend.cancel(message_t* msg) {
	dbg("Network", "trickleNetP NetworkAMSend.cancel(0x%1x)", msg);
	return call MacAMSend.cancel(msg);
}


command uint8_t NetworkAMSend.maxPayloadLength() {
	dbg("Network", "trickleNetP NetworkAMSend.maxPayloadLength()");
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct trickle_net_header));
}


command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "trickleNetP NetworkAMSend.getpayload(0x%1x, %d )", msg, len);
	ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct trickle_net_header));
	return (void*) (ptr + sizeof(nx_struct trickle_net_header));
}


event void MacAMSend.sendDone(message_t *msg, error_t error) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*)
		call MacAMSend.getPayload(msg, sizeof(nx_struct trickle_net_header));
	dbg("Network", "trickleNetP NetworkAMSend.sendDone(0x%1x, %d )", msg, error);
	tx_busy = FALSE;
	if (header->flags == TRICKLE_DATA) {
		signal NetworkAMSend.sendDone(msg, error);
	}
}


message_t * receive_data(message_t *msg, void* payload, uint8_t len) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*) payload;
	uint8_t *ptr = (uint8_t*) payload;

	dbg("Network", "trickleNetP receive_data(0x%1x, 0x%1x, %d )", msg, payload, len);

	if (seqno == DISSEMINATION_SEQNO_UNKNOWN &&
		header->seq != DISSEMINATION_SEQNO_UNKNOWN) {

		dbg("Network", "trickleNetP NetworkReceive.receive(0x%1x, 0x%1x, %d )", msg, 
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

	if (header->seq == DISSEMINATION_SEQNO_UNKNOWN &&
		seqno != DISSEMINATION_SEQNO_UNKNOWN) {
		call TrickleTimer.reset[TRICKLE_ID]();
		return msg;
	}

	if ((int32_t)(header->seq - seqno) > 0) {
		memcpy(&data_msg, msg, sizeof(message_t));
		data_len = len;
		seqno = header->seq;
		call TrickleTimer.reset[TRICKLE_ID]();

		dbg("Network", "trickleNetP NetworkReceive.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));

		return signal NetworkReceive.receive(msg, 
			ptr + sizeof(nx_struct trickle_net_header), 
			len - sizeof(nx_struct trickle_net_header));

	} else if ( (int32_t)(header->seq - seqno) == 0) {
		call TrickleTimer.incrementCounter[TRICKLE_ID]();
	} else {
		/* Trickle source code is not sure what to do about it */
		/* Immediate send */
		send_message(&data_msg, data_len, TRICKLE_DATA);
	}
	return msg;
}


message_t * receive_probe(message_t *msg, void* payload, uint8_t len) {
	send_message(&data_msg, data_len, TRICKLE_DATA);
	dbg("Network", "trickleNetP receive_probe(0x%1x, 0x%1x, %d )", msg, payload, len); 
	return msg;
}


event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct trickle_net_header *header = (nx_struct trickle_net_header*) payload;

	if (header->flags == TRICKLE_DATA) {
		return receive_data(msg, payload, len);
	}
	
	if (header->flags == TRICKLE_BEACON) {
		return receive_probe(msg, payload, len);
	}
	return msg;

}


event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "trickleNetP NetworkSnoop.receive(0x%1x, 0x%1x, %d )", msg, 
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

}


default command error_t TrickleTimer.start[uint16_t key]() { return FAIL; }
default command void TrickleTimer.stop[uint16_t key]() { }
default command void TrickleTimer.reset[uint16_t key]() { }
default command void TrickleTimer.incrementCounter[uint16_t key]() { }

}
