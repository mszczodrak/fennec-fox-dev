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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include <Ieee154.h> 
#include "csmacaMac.h"


module csmacaMacP @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;

provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmacaMacParams;

uses interface SplitControl as RadioControl;

uses interface RadioPacket;
uses interface Resource as RadioResource;

uses interface LinkPacketMetadata as RadioLinkPacketMetadata;


uses interface Send as SubSend;
uses interface Receive as SubReceive;

uses interface Random;
uses interface Leds;
}

implementation {

uint8_t status = S_STOPPED;
message_t * ONE_NOK pending_message = NULL;

uint8_t localSendId;

command error_t SplitControl.start() {
	error_t e;
	dbg("Mac", "csmaMac SplitControl.start()");
	if (status == S_STARTED) {
		signal SplitControl.startDone(SUCCESS);
		return SUCCESS;
	}

	localSendId = call Random.rand16();

	e = call RadioControl.start();

	if (e == EALREADY) {
		status = S_STARTING;
		signal RadioControl.startDone(EALREADY);
	}

	if (e == FAIL) {
		signal SplitControl.startDone(FAIL);
		return FAIL;
	}

	dbg("Mac", "csmaMac SplitControl.stop - STARTING");
	status = S_STARTING;
	return SUCCESS;
}

command error_t SplitControl.stop() {
	error_t e;
	dbg("Mac", "csmaMac SplitControl.stop()");
	if (status == S_STOPPED) {
		signal SplitControl.stopDone(SUCCESS);
		return SUCCESS;
	}

	e = call RadioControl.stop();

	if (e == EALREADY) {
		status = S_STOPPING;
		signal RadioControl.stopDone(EALREADY);
	}

	if (e == FAIL) {
		signal SplitControl.stopDone(FAIL);
		return FAIL;
	}

	dbg("Mac", "csmaMac SplitControl.stop - STOPPING");

	status = S_STOPPING;
	return SUCCESS;
}


event void RadioControl.startDone(error_t err) {
	dbg("Mac", "csmaMac RadioControl.startDone(%d)", err);
	if (status != S_STARTING) {
		return;
	}

	if (err == FAIL) {
		call RadioControl.start();
	} else {
		status = S_STARTED;
		signal SplitControl.startDone(SUCCESS);
	}
}


event void RadioControl.stopDone(error_t err) {
	dbg("Mac", "csmaMac RadioControl.stopDone(%d)", err);
	if (status != S_STOPPING) {
		return;
	}

	if (err == FAIL) {
		call RadioControl.stop();
	} else {
		status = S_STOPPED;
		signal SplitControl.stopDone(SUCCESS);
	}
}

command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	csmaca_header_t* header;

	dbg("Mac", "csmaMac MacAMSend.send(%d, 0x%1x, %d)", addr, msg, len);

	header = (csmaca_header_t*)call SubSend.getPayload( msg, len );

	call MacAMPacket.setGroup(msg, msg->conf);

	getMetadata(msg)->crc = 0;
	getMetadata(msg)->rssi = 0;
	getMetadata(msg)->lqi = 0;

	if (len > call MacPacket.maxPayloadLength()) {
		return ESIZE;
	}

	header->dest = addr;
	header->src = call MacAMPacket.address();
	header->fcf |= ( 1 << IEEE154_FCF_INTRAPAN ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;

	call MacPacket.setPayloadLength(msg, len);

	return call SubSend.send( msg, len );
}

command error_t MacAMSend.cancel(message_t* msg) {
	dbg("Mac", "csmaMac MacAMSend.cancel(0x%1x)", msg);
	return call SubSend.cancel(msg);
}

command uint8_t MacAMSend.maxPayloadLength() {
	dbg("Mac-Detail", "csmaMac MacAMSend.maxPayloadLength()");
	return call MacPacket.maxPayloadLength();
}

command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac-Detail", "csmaMac MacAMSend.getPayload(0x%1x, %d)", msg, len);
	return call MacPacket.getPayload(msg, len);
}

/***************** PacketAcknowledgement Commands ****************/
async command error_t MacPacketAcknowledgements.requestAck( message_t* m ) {
        uint8_t *p = (uint8_t*)(m->data);
        csmaca_header_t* header = (csmaca_header_t*) (p + call RadioPacket.headerLength(m));
	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* m ) {
        uint8_t *p = (uint8_t*)(m->data);
        csmaca_header_t* header = (csmaca_header_t*) (p + call RadioPacket.headerLength(m));
	header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	return SUCCESS;
}

async command bool MacPacketAcknowledgements.wasAcked( message_t* p_msg ) {
	metadata_t* metadata = (metadata_t*) p_msg->metadata;
	return metadata->ack;
}


event void RadioResource.granted() {

}


/***************** AMPacket Commands ****************/
command am_addr_t MacAMPacket.address() {
	return TOS_NODE_ID;
}

command am_addr_t MacAMPacket.destination(message_t* amsg) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	return header->dest;
}

command am_addr_t MacAMPacket.source(message_t* amsg) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	return header->src;
}

command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	header->dest = addr;
}

command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	header->src = addr;
}


command bool MacAMPacket.isForMe(message_t* amsg) {
	return (call MacAMPacket.destination(amsg) == call MacAMPacket.address() ||
            call MacAMPacket.destination(amsg) == AM_BROADCAST_ADDR);
}

command am_id_t MacAMPacket.type(message_t* amsg) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	return header->type;
}

command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	header->type = type;
}

command am_group_t MacAMPacket.group(message_t* amsg) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	return header->destpan;
}

command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	// Overridden intentionally when we send()
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(amsg, sizeof(csmaca_header_t));
	header->destpan = grp;
}

command am_group_t MacAMPacket.localGroup() {
	return 0;
//    return call CC2420Config.getPanAddr();
}


/***************** Packet Commands ****************/
command void MacPacket.clear(message_t* msg) {
	call RadioPacket.clear(msg);
}

command uint8_t MacPacket.payloadLength(message_t* msg) {
	return call RadioPacket.payloadLength(msg) - sizeof(csmaca_header_t);
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
	call RadioPacket.setPayloadLength(msg, len + sizeof(csmaca_header_t));
}

command uint8_t MacPacket.maxPayloadLength() {
	return call RadioPacket.maxPayloadLength() - sizeof(csmaca_header_t);
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	if (len <= call SubSend.maxPayloadLength()) {
		uint8_t *p = (uint8_t*) call SubSend.getPayload(msg, len);
		return (p + sizeof(csmaca_header_t));
	} else {
		return NULL;
	}
}

/***************** SubSend Events ****************/
event void SubSend.sendDone(message_t* msg, error_t result) {
	printf("sendDone error: %u \t rssi: %u \t lqi: %u \t crc: %u \t ack: %u\n",
		result, getMetadata(msg)->rssi, getMetadata(msg)->lqi, getMetadata(msg)->crc, getMetadata(msg)->ack);
	printfflush();
	dbg("Mac", "csmaMac SubSend.sendDone(0x%1x, %d)", msg, result);
	signal MacAMSend.sendDone(msg, result);
}

/***************** SubReceive Events ****************/
event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	uint8_t *ptr;
	atomic {
		ptr = (uint8_t*) payload;
		ptr += sizeof(csmaca_header_t);
		len -= sizeof(csmaca_header_t);

		dbg("Mac", "csmaMac SubReceive.receive(0x%1x, 0x%1x, %d)", msg, payload, len);

		if((call csmacaMacParams.get_crc()) && (!getMetadata(msg)->crc)) {
			return msg;
		}
	}

	printf("rssi: %u \t lqi: %u \t crc: %u \t ack: %u\n", 
			getMetadata(msg)->rssi, getMetadata(msg)->lqi, 
			getMetadata(msg)->crc, getMetadata(msg)->ack);
	printfflush();

	if (call MacAMPacket.isForMe(msg)) {
		return signal MacReceive.receive(msg, ptr, len);
	} else {
		return signal MacSnoop.receive(msg, ptr, len);
	}
}


async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call RadioLinkPacketMetadata.highChannelQuality(msg);
}

}

