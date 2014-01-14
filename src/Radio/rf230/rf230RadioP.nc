/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox rf230 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/11/2014
  */


#include <Fennec.h>
#include "rf230Radio.h"

module rf230RadioP @safe() {
provides interface SplitControl;
provides interface RadioReceive;
provides interface Resource as RadioResource;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;

uses interface rf230RadioParams;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

uint8_t channel;
norace uint8_t state = S_STOPPED;
norace message_t *m;
bool sc = FALSE;

task void start_done() {
	state = S_STARTED;
	signal RadioState.done();
	if (sc == TRUE) {
		signal SplitControl.startDone(SUCCESS);
		sc = FALSE;
	}
}

task void finish_starting_radio() {
	post start_done();
}

task void stop_done() {
	state = S_STOPPED;
	signal RadioState.done();
	if (sc == TRUE) {
		signal SplitControl.stopDone(SUCCESS);
		sc = FALSE;
	}
}

command error_t SplitControl.start() {
	sc = TRUE;
	return call RadioState.turnOn();
}


command error_t SplitControl.stop() {
	sc = TRUE;
	return call RadioState.turnOff();
}


command error_t RadioState.turnOn() {
	dbg("Radio", "rf230Radio SplitControl.start()");

	if (state == S_STOPPED) {
		state = S_STARTING;
		post start_done();
		return SUCCESS;

	} else if(state == S_STARTED) {
		post start_done();
		return EALREADY;

	} else if(state == S_STARTING) {
		return SUCCESS;
	}
	return SUCCESS;
}

command error_t RadioState.turnOff() {
	dbg("Radio", "rf230Radio SplitControl.stop()");
	if (state == S_STARTED) {
		state = S_STOPPING;
		post stop_done();
		return SUCCESS;
	} else if(state == S_STOPPED) {
		post stop_done();
		return EALREADY;
	} else if(state == S_STOPPING) {
		return SUCCESS;
	}
	return SUCCESS;
}

command error_t RadioState.standby() {
	return call RadioState.turnOff();
}

command error_t RadioState.setChannel(uint8_t new_channel) {
	channel = new_channel;
	signal RadioState.done();
        return SUCCESS;
}

command uint8_t RadioState.getChannel() {
        return channel;
}



async command error_t RadioCCA.request() {
	return SUCCESS;
}

task void load_done() {
	signal RadioBuffer.loadDone(m, SUCCESS);
}

async command error_t RadioBuffer.load(message_t* msg) {
	dbg("Radio", "rf230Radio RadioBuffer.load(0x%1x)", msg);
	m = msg;
	post load_done();
	return SUCCESS;
}

task void send_done() {
	signal RadioSend.sendDone(m, SUCCESS);
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	dbg("Radio", "rf230Radio RadioBuffer.send(0x%1x)", msg, useCca);
	post send_done();
	return SUCCESS;
}

async command uint8_t RadioPacket.maxPayloadLength() {
	dbg("Radio", "rf230Radio RadioBuffer.maxPayloadLength()");
	return RF230_MAX_MESSAGE_SIZE - sizeof(nx_struct rf230_radio_header_t) - RF230_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	return sizeof(nx_struct rf230_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct rf230_radio_header_t *hdr = (nx_struct rf230_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct rf230_radio_header_t) - RF230_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct rf230_radio_header_t *hdr = (nx_struct rf230_radio_header_t*)(msg->data);
	hdr->length = length + sizeof(nx_struct rf230_radio_header_t) + RF230_SIZEOF_CRC + sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
        return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
        memset(msg, 0x0, sizeof(message_t));
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

async command bool RadioLinkPacketMetadata.highChannelQuality(message_t* msg) {
       //      return call PacketLinkQuality.get(msg) > 105;
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

async command bool PacketTimeSyncOffset.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<3);
}
    
async command uint8_t PacketTimeSyncOffset.get(message_t* msg) {
	// TODO:
	//return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
	return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg);
}

async command void PacketTimeSyncOffset.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<3);
}

async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value) {
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

