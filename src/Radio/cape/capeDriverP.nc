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
  * Cape Fox radio driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/28/2013
  */



#include <Fennec.h>
#include "cape.h"

module capeDriverP @safe() {

provides interface RadioState;

provides interface RadioReceive;
provides interface Resource as RadioResource;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;

uses interface capeParams;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;

uses interface SplitControl as AMControl;

uses interface TossimPacketModel as Model;
}

implementation {

uint8_t channel;
norace uint8_t cape_radio_state = S_STOPPED;

norace message_t *out_msg;
norace error_t err;

message_t buffer;
message_t* bufferPointer = &buffer;
uint8_t auto_ack;

task void start_done() {
	cape_radio_state = S_STARTED;	
	dbg("Radio-Detail", "[-] cape signal RadioState.done()");
	signal RadioState.done();
}

task void stop_done() {
	cape_radio_state = S_STOPPED;
	signal RadioState.done();
}

task void load_done() {
	signal RadioBuffer.loadDone(out_msg, err);
}


task void send_done() {
	if (out_msg != NULL) {
		signal RadioSend.sendDone(out_msg, err);
	}
	out_msg = NULL;
}

task void cancel_msg() {
	call Model.cancel(out_msg);
}

command error_t RadioState.standby() {
        return call RadioState.turnOff();
}


command error_t RadioState.turnOn() {
        if (cape_radio_state == S_STARTED) {
		dbg("Radio-Detail", "[-] cape RadioState.turnOn() - EALREADY");
                return EALREADY;
        }

	auto_ack = TRUE;
	dbg("Radio-Detail", "[-] cape RadioState.turnOn()");
	out_msg = NULL;
	
        cape_radio_state = S_STARTING;

	call AMControl.start();
	call RadioResource.release();

        post start_done();
        return SUCCESS;
}

event void AMControl.startDone(error_t error) {
}

event void AMControl.stopDone(error_t error) {
}

command error_t RadioState.turnOff() {
        if (cape_radio_state == S_STOPPED) {
		dbg("Radio-Detail", "[-] cape RadioState.turnOff() - EALREADY");
                return EALREADY;
        }

	dbg("Radio-Detail", "[-] cape RadioState.turnOff()");
	call AMControl.stop();

        err = SUCCESS;

        if (err != SUCCESS) return FAIL;

        cape_radio_state = S_STOPPING;
        post stop_done();
        return SUCCESS;
}

command uint8_t RadioState.getChannel() {
	return channel;
}

command error_t RadioState.setChannel(uint8_t new_channel) {
	atomic channel = new_channel;
	signal RadioState.done();
	return SUCCESS;
}

async command error_t RadioBuffer.load(message_t* msg) {
	cape_hdr_t* header = (cape_hdr_t*) msg->data;

        if (cape_radio_state != S_STARTED) {
		dbg("Radio", "[%d] cape RadioBuffer.load(0x%1x) - EOFF (%d)", header->destpan, msg, cape_radio_state);
                return EOFF;
        }

	if (out_msg != NULL) {
		dbg("Radio", "[%d] cape RadioSend.load( 0x%1x ) - EBUSY", header->destpan, msg);
		return EBUSY;
	}

	dbg("Radio", "[%d] cape RadioSend.load( 0x%1x )", header->destpan, msg);
	out_msg = msg;
	err = SUCCESS;
	post load_done();
	return SUCCESS;
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	cape_hdr_t* header = (cape_hdr_t*) msg->data;

        if (cape_radio_state != S_STARTED) {
		dbg("Radio", "[%d] cape RadioSend.send(0x%1x, %d) - EOFF (%d)", header->destpan, msg, useCca, cape_radio_state);
                return EOFF;
        }

	if (msg != out_msg) {
		dbg("Radio", "[%d] cape RadioSend.send(0x%1x, %d )  FAILED", header->destpan, msg, useCca);
		return FAIL;
	} else {
		dbg("Radio", "[%d] cape RadioSend.send(0x%1x, %d )", header->destpan, msg, useCca);

		if ((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1) {
			metadata_t* metadata = getMetadata(out_msg);
			metadata->ack = 1;
		}

		err = call Model.send(BROADCAST, out_msg, header->length);
		dbg("Radio", "[%d] cape Model.send(BROADCAST, 0x%1x)  - %d", header->destpan, out_msg, err);
		return err;
	}
}

async command error_t RadioResource.immediateRequest() {
	return SUCCESS;
}

async command error_t RadioResource.request() {
	return SUCCESS;
}

async command bool RadioResource.isOwner() {
	return SUCCESS;
}

async command error_t RadioResource.release() {
	return SUCCESS;
}


event void Model.sendDone(message_t* msg, error_t result) {
	cape_hdr_t* header;
	if (msg == NULL) {
		dbg("Radio-Detail", "[-] cape Model.sendDone returned with NULL pointer !!");
		return;
	} 
	header = (cape_hdr_t*) msg->data;
	if (msg != out_msg) {
		dbg("Radio", "[%d] cape Model.sendDone returned incorrect msg pointer", header->destpan);
		dbg("Radio", "[%d] cape Model.sendDone got 0x%1x instead of 0x%1x", header->destpan, msg, out_msg);
		err = FAIL;
	} 
	dbg("Radio", "[%d] cape Model.sendDone(0x%1x, %d )", header->destpan, msg, result);
	err = result;
	post send_done();
}

event void Model.receive(message_t* msg) {
	cape_hdr_t* header = (cape_hdr_t*) msg->data;
	dbg("Radio", "[%d] cape ModelReceive.receive(0x%1x)", header->destpan, msg);
	if (signal RadioReceive.header(msg)) {
		metadata_t* metadata;

		memcpy(bufferPointer, msg, sizeof(message_t));

		metadata = (metadata_t*)getMetadata( bufferPointer );
		metadata->crc = 1; /* always PASS crc */
		metadata->lqi = 0;
		metadata->rssi = metadata->strength;

		dbg("Radio", "[%d] cape RadioReceive.receive(0x%1x)", header->destpan, bufferPointer);
		bufferPointer = signal RadioReceive.receive(bufferPointer);
	}
}

event bool Model.shouldAck(message_t* msg) {
	cape_hdr_t* header = (cape_hdr_t*) msg->data;

	if ( (header->dest == TOS_NODE_ID) && (header->fcf & (1 << IEEE154_FCF_ACK_REQ)) ) {  	
		dbg("Radio", "[%d] cape Model.shouldAck(0x%1x) - TRUE", header->destpan, msg);
		return TRUE;
	}
	return FALSE;
}

void active_message_deliver_handle(sim_event_t* evt) {
	message_t* mg = (message_t*)evt->data;
	cape_hdr_t* header = (cape_hdr_t*) mg->data;
	dbg("cape", "[%d] Delivering packet to %i at %s\n", header->destpan, (int)sim_node(), sim_time_string());
	signal Model.receive(mg);
}

sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t) {
	sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
	evt->mote = node;
	evt->time = t;
	evt->handle = active_message_deliver_handle;
	evt->cleanup = sim_queue_cleanup_event;
	evt->cancelled = 0;
	evt->force = 0;
	evt->data = msg;
	return evt;
}

void active_message_deliver(int node, message_t* msg, sim_time_t t) @spontaneous() {
	sim_event_t* evt = allocate_deliver_event(node, msg, t);
	sim_queue_insert(evt);
}


/* Radio Packet */

async command uint8_t RadioPacket.maxPayloadLength() {
        return CAPE_MAX_MESSAGE_SIZE - sizeof(nx_struct cape_radio_header_t) - CAPE_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
        return sizeof(nx_struct cape_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
        nx_struct cape_radio_header_t *hdr = (nx_struct cape_radio_header_t*)(msg->data);
        return hdr->length - sizeof(nx_struct cape_radio_header_t) - CAPE_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
        nx_struct cape_radio_header_t *hdr = (nx_struct cape_radio_header_t*)(msg->data);
        hdr->length = length + sizeof(nx_struct cape_radio_header_t) + CAPE_SIZEOF_CRC + sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
        return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
        memset(msg, 0x0, sizeof(message_t));
}





async command bool RadioLinkPacketMetadata.highChannelQuality(message_t* msg) {
        return call PacketLinkQuality.get(msg) > 105;
}

async command bool PacketTransmitPower.isSet(message_t* msg) {
        return getMetadata(msg)->flags & (1<<1);
}

async command uint8_t PacketTransmitPower.get(message_t* msg) {
        return getMetadata(msg)->tx_power;
}

async command void PacketTransmitPower.clear(message_t* msg) {
        getMetadata(msg)->flags &= ~(1<<1);
}

async command void PacketTransmitPower.set(message_t* msg, uint8_t value) {
        getMetadata(msg)->flags |= (1<<1);
        getMetadata(msg)->tx_power = value;
}


async command bool PacketRSSI.isSet(message_t* msg) {
        return getMetadata(msg)->flags & (1<<2);
}

async command uint8_t PacketRSSI.get(message_t* msg) {
        return getMetadata(msg)->rssi;
}

async command void PacketRSSI.clear(message_t* msg) {
        getMetadata(msg)->flags &= ~(1<<2);
}

async command void PacketRSSI.set(message_t* msg, uint8_t value) {
        call PacketTransmitPower.clear(msg);
        getMetadata(msg)->flags |= (1<<2);
        getMetadata(msg)->rssi = value;
}

async command bool PacketTimeSync.isSet(message_t* msg) {
        return getMetadata(msg)->flags & (1<<3);
}

async command uint32_t PacketTimeSync.get(message_t* msg) {
	return (uint32_t)(*((msg->data) + (call RadioPacket.headerLength(msg) +
		call RadioPacket.payloadLength(msg))));
}

async command void PacketTimeSync.clear(message_t* msg) {
        getMetadata(msg)->flags &= ~(1<<3);
}

async command void PacketTimeSync.set(message_t* msg, uint32_t value) {
        getMetadata(msg)->flags |= (1<<3);
        // we do not store the value, the time sync field is always the last 4 bytes
}

async command bool PacketLinkQuality.isSet(message_t* msg) {
        return TRUE;
}

async command uint8_t PacketLinkQuality.get(message_t* msg) {
        return getMetadata(msg)->lqi;
}

async command void PacketLinkQuality.clear(message_t* msg){
}

async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
        getMetadata(msg)->lqi = value;
}



}

