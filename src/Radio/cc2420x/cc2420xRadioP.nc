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
  * Fennec Fox cc2420x radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */


#include <Fennec.h>
#include "cc2420xRadio.h"
#include "CC2420TimeSyncMessage.h"

module cc2420xRadioP @safe() {
provides interface SplitControl;
provides interface RadioReceive;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;

uses interface cc2420xRadioParams;

uses interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

uint8_t channel;
norace uint8_t state = S_STOPPED;
norace message_t *m;

task void start_done() {
	state = S_STARTED;
	signal SplitControl.startDone(SUCCESS);
}

task void stop_done() {
	state = S_STOPPED;
	signal SplitControl.stopDone(SUCCESS);
}

command error_t SplitControl.start() {
	state = S_STARTING;
	return call RadioState.turnOn();
}


command error_t SplitControl.stop() {
	state = S_STOPPING;
	return call RadioState.turnOff();
}


event void RadioState.done() {
	switch(state) {
	case S_STARTING:
		post start_done();		
		break;

	case S_STOPPING:
		post stop_done();
		break;

	default:
		break;

	}
}



async command error_t RadioCCA.request() {
	return SUCCESS;
}

task void load_done() {
	signal RadioBuffer.loadDone(m, SUCCESS);
}

async command error_t RadioBuffer.load(message_t* msg) {
	dbg("Radio", "cc2420xRadio RadioBuffer.load(0x%1x)", msg);
	m = msg;
	signal RadioBuffer.loadDone(msg, SUCCESS);
	return SUCCESS;
}

task void send_done() {
	signal RadioSend.sendDone(m, SUCCESS);
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	dbg("Radio", "cc2420xRadio RadioBuffer.send(0x%1x)", msg, useCca);
	post send_done();
	return SUCCESS;
}

async command uint8_t RadioPacket.maxPayloadLength() {
	dbg("Radio", "cc2420xRadio RadioBuffer.maxPayloadLength()");
	return NULL_MAX_MESSAGE_SIZE - sizeof(nx_struct cc2420x_radio_header_t) - NULL_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	return sizeof(nx_struct cc2420x_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct cc2420x_radio_header_t *hdr = (nx_struct cc2420x_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct cc2420x_radio_header_t) - NULL_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct cc2420x_radio_header_t *hdr = (nx_struct cc2420x_radio_header_t*)(msg->data);
	hdr->length = length + sizeof(nx_struct cc2420x_radio_header_t) + NULL_SIZEOF_CRC + sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
        return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
        memset(msg, 0x0, sizeof(message_t));
}



async command bool RadioLinkPacketMetadata.highChannelQuality(message_t* msg) {
       //      return call PacketLinkQuality.get(msg) > 105;
}




}

