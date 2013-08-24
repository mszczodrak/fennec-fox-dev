/*
 *  cape radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
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
 * Network: cape Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "capeRadio.h"

module capeRadioP @safe() {

provides interface Mgmt;
provides interface Receive as RadioReceive;
provides interface ModuleStatus as RadioStatus;
provides interface Resource as RadioResource;
provides interface RadioConfig;
provides interface RadioPower;
provides interface Read<uint16_t> as ReadRssi;
provides interface SplitControl as RadioControl;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;
provides interface ReceiveIndicator as PacketIndicator;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

uses interface capeRadioParams;

uses interface SplitControl as AMControl;

uses interface TossimPacketModel as Model;
}

implementation {

uint8_t channel;
norace uint8_t state = S_STOPPED;

norace message_t *out_msg;
norace error_t err;

message_t buffer;
message_t* bufferPointer = &buffer;
uint8_t auto_ack;

task void start_done() {
	state = S_STARTED;
	dbg("Radio", "capeRadio start_done()");
	signal RadioControl.startDone(SUCCESS);
	signal Mgmt.startDone(SUCCESS);
}

task void stop_done() {
	state = S_STOPPED;
	dbg("Radio", "capeRadio stop_done()");
	signal RadioControl.stopDone(SUCCESS);
	signal Mgmt.stopDone(SUCCESS);
}

task void load_done() {
	signal RadioBuffer.loadDone(out_msg, err);
}


task void send_done() {
	signal RadioSend.sendDone(out_msg, err);
	out_msg = NULL;
}

task void send_msg() {
	fennec_header_t *header;

	header = (fennec_header_t*)call RadioPacket.getPayload(out_msg,
						sizeof(fennec_header_t));
	err = call Model.send(BROADCAST, out_msg, header->length);
	dbg("Radio", "capeRadio Model.send(BROADCAST, 0x%1x)  - %d", out_msg, err);
	if (err != SUCCESS) {
		post send_done();
	}
}


command error_t Mgmt.start() {
	auto_ack = TRUE;
	state = S_STOPPED;
	dbg("Radio", "capeRadio Mgmt.start()");
	call RadioControl.start();
	return SUCCESS;
}

event void AMControl.startDone(error_t error) {
	state = S_STARTED;
	post start_done();
}

event void AMControl.stopDone(error_t error) {
	state = S_STOPPED;
	post stop_done();
}

command error_t Mgmt.stop() {
	dbg("Radio", "capeRadio Mgmt.stop()");
	call RadioControl.stop();
	return SUCCESS;
}

command error_t RadioControl.start() {
	dbg("Radio", "capeRadio RadioControl.start()");
	if (state == S_STOPPED) {
		state = S_STARTING;
		call AMControl.start();
		return SUCCESS;
	} else if(state == S_STARTED) {
		post start_done();
		return EALREADY;
	} else if(state == S_STARTING) {
		return SUCCESS;
	}

	return EBUSY;
}

command error_t RadioControl.stop() {
	dbg("Radio", "RadioControl.stop");
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
	return EBUSY;
}

event void capeRadioParams.receive_status(uint16_t status_flag) {
}

async command error_t RadioPower.startVReg() {
	return SUCCESS;
}

async command error_t RadioPower.stopVReg() {
	return SUCCESS;
}

async command error_t RadioPower.startOscillator() {
	return SUCCESS;
}

async command error_t RadioPower.stopOscillator() {
	return SUCCESS;
}

async command error_t RadioPower.rxOn() {
	return SUCCESS;
}

async command error_t RadioPower.rfOff() {
	return SUCCESS;
}

command uint8_t RadioConfig.getChannel() {
	return channel;
}

command void RadioConfig.setChannel( uint8_t new_channel ) {
	atomic channel = new_channel;
}

async command uint16_t RadioConfig.getShortAddr() {
	return TOS_NODE_ID;
}

command void RadioConfig.setShortAddr( uint16_t addr ) {
}

async command uint16_t RadioConfig.getPanAddr() {
	return TOS_NODE_ID;
}

command void RadioConfig.setPanAddr( uint16_t pan ) {
}

command error_t RadioConfig.sync() {
	return SUCCESS;
}

command void RadioConfig.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
}

async command bool RadioConfig.isAddressRecognitionEnabled() {
	return FALSE;
}

async command bool RadioConfig.isHwAddressRecognitionDefault() {
	return FALSE;
}

command void RadioConfig.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
}

async command bool RadioConfig.isHwAutoAckDefault() {
	return FALSE;
}

async command bool RadioConfig.isAutoAckEnabled() {
	return FALSE;
}

command error_t ReadRssi.read() {
	return FAIL;
}

async command bool ByteIndicator.isReceiving() {
	return FALSE;
}

async command bool EnergyIndicator.isReceiving() {
	return FALSE;
}

async command bool PacketIndicator.isReceiving() {
	return FALSE;
}

async command error_t RadioBuffer.load(message_t* msg) {
	dbg("Radio", "capeRadio RadioSend.load( 0x%1x )", msg);
	out_msg = msg;
	err = SUCCESS;
	post load_done();
	return SUCCESS;
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	if (msg != out_msg) {
		dbg("Radio", "capeRadio RadioSend.send(0x%1x, %d )  FAILED", msg, useCca);
		return FAIL;
	} else {
		dbg("Radio", "capeRadio RadioSend.send(0x%1x, %d )", msg, useCca);
		post send_msg();
		return SUCCESS;
	}
}

async command error_t RadioSend.cancel(message_t *msg) {
	return call Model.cancel(msg);
}

async command uint8_t RadioPacket.maxPayloadLength() {
	return 128;
}

async command void* RadioPacket.getPayload(message_t* msg, uint8_t len) {
	dbg("Radio", "capeRadio RadioSend.getPayload( 0x%1x, %d )", msg, len);
	if (len <= call RadioPacket.maxPayloadLength()) {
		return (void*)msg->data;
	} else {
		return NULL;
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
	if (msg != out_msg) {
		dbg("Radio", "capeRadio Model.sendDone returned incorred msg pointer");
		err = FAIL;
	} 
	dbg("Radio", "capeRadio Model.sendDone(0x%1x, %d )", msg, result);
	err = result;
	post send_done();
}

event void Model.receive(message_t* msg) {
	uint8_t len;
	void* payload;
	metadata_t* metadata;
	fennec_header_t *header; 

	memcpy(bufferPointer, msg, sizeof(message_t));

	metadata = (metadata_t*)getMetadata( bufferPointer );
	metadata->crc = 1; /* always PASS crc */

	header = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
						sizeof(fennec_header_t));

	len = header->length;
	payload = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
                                                sizeof(len));
	
	dbg("Radio", "capeRadio RadioReceive.receive(0x%1x, 0x%1x, %d )", msg, payload, len);

	bufferPointer = signal RadioReceive.receive(bufferPointer, payload, len);
}

event bool Model.shouldAck(message_t* msg) {
	fennec_header_t *header;
	header = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
						sizeof(fennec_header_t));

	if (header->dest == TOS_NODE_ID) { 	
		dbg("Radio", "capeRadio Model.shouldAck(0x%1x) - TRUE", msg);
		return TRUE;
	}
	return FALSE;
}

void active_message_deliver_handle(sim_event_t* evt) {
	message_t* mg = (message_t*)evt->data;
	dbg("capeRadio", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());
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

void active_message_deliver(int node, message_t* msg, sim_time_t t) @C() @spontaneous() {
	sim_event_t* evt = allocate_deliver_event(node, msg, t);
	sim_queue_insert(evt);
}


}

