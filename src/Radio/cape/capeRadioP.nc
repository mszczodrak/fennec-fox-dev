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

provides interface SplitControl;
provides interface RadioState;

provides interface RadioReceive;
provides interface Resource as RadioResource;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;

uses interface capeRadioParams;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;


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
uint8_t sc = FALSE;

task void start_done() {
        if (err == SUCCESS) {
                state = S_STARTED;
        }
	signal RadioState.done();
	if (sc == TRUE) {
		dbg("Radio", "capeRadio signal SplitControl.startDone(%d)", err);
		signal SplitControl.startDone(err);
		sc = FALSE;
	}
}

task void finish_starting_radio() {
        if (call RadioPower.rxOn() != SUCCESS) err = FAIL;
        if (call RadioResource.release() != SUCCESS) err = FAIL;
        //if (call ReceiveControl.start() != SUCCESS) err = FAIL;
        //if (call TransmitControl.start() != SUCCESS) err = FAIL;
	dbg("Radio", "capeRadio finish_starting_radio()");
        post start_done();
}

task void stop_done() {
        if (err == SUCCESS) {
                state = S_STOPPED;
        }
	signal RadioState.done();
	if (sc == TRUE) {
		dbg("Radio", "capeRadio signal SplitControl.stopDone(%d)", err);
		signal SplitControl.stopDone(err);
		sc = FALSE;
	}
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
	metadata_t* metadata;

	header = (fennec_header_t*)call RadioPacket.getPayload(out_msg,
						sizeof(fennec_header_t));
	metadata = getMetadata(out_msg);

	metadata->ack = ( header->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) );

	err = call Model.send(BROADCAST, out_msg, header->length);
	//dbg("Radio", "capeRadio Model.send(BROADCAST, 0x%1x)  - %d", out_msg, err);
	if (err != SUCCESS) {
		post send_done();
	}
}

task void cancel_msg() {
	call Model.cancel(out_msg);
}

command error_t RadioState.standby() {
        return call RadioState.turnOff();
}


command error_t RadioState.turnOn() {
	auto_ack = TRUE;
	dbg("Radio", "capeRadio SplitControl.start()");
	call AMControl.start();

        err = SUCCESS;

        if (state == S_STARTED) {
                post start_done();
                return SUCCESS;
        }

        if (call RadioPower.startVReg() != SUCCESS) {
		dbg("Radio", "capeRadio RadioPower.startVReg() - FAILED");
		return FAIL;
	}
        state = S_STARTING;
        return SUCCESS;
}

event void AMControl.startDone(error_t error) {
}

event void AMControl.stopDone(error_t error) {
}

command error_t RadioState.turnOff() {
	dbg("Radio", "capeRadio SplitControl.stop()");
	call AMControl.stop();

        err = SUCCESS;

        if (state == S_STOPPED) {
                post stop_done();
                return SUCCESS;
        }

        //if (call ReceiveControl.stop() != SUCCESS) err = FAIL;
        //if (call TransmitControl.stop() != SUCCESS) err = FAIL;
        if (call RadioPower.stopVReg() != SUCCESS) err = FAIL;

        if (err != SUCCESS) return FAIL;

        state = S_STOPPING;
        post stop_done();
        return SUCCESS;
}

command error_t SplitControl.start() {
	sc = TRUE;
	return call RadioState.turnOn();
}


command error_t SplitControl.stop() {
	sc = TRUE;
	return call RadioState.turnOff();
}



task void start_v_reg_done() {
	call RadioPower.startOscillator();
}

async command error_t RadioPower.startVReg() {
	dbg("Radio", "capeRadio RadioPower.startVReg()");
	post start_v_reg_done();
	return SUCCESS;
}

async command error_t RadioPower.stopVReg() {
	return SUCCESS;
}

task void start_oscillator_done() {
        post finish_starting_radio();
}

async command error_t RadioPower.startOscillator() {
	dbg("Radio", "capeRadio RadioPower.startOscillator()");
	post start_oscillator_done();
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
	if (out_msg == msg) {
		post cancel_msg();
		return SUCCESS;
	}
	return FAIL;
}

async command uint8_t RadioPacket.maxPayloadLength() {
	//dbg("Radio", "capeRadioP RadioPacket.maxPayloadLength()");
	return 128;
}

async command void* RadioPacket.getPayload(message_t* msg, uint8_t len) {
	//dbg("Radio", "capeRadio RadioSend.getPayload( 0x%1x, %d )", msg, len);
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
	fennec_header_t * header = (fennec_header_t*) msg->data;
	if ( header->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
		dbg("Radio", "capeRadio wait for ACCCCCCCCCCCCCKKKKKKKKKKKKKKKKKKKKKK");
	}


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
	metadata->lqi = 0;
	metadata->rssi = metadata->strength;

	header = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
						sizeof(fennec_header_t));

	len = header->length;
	payload = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
                                                sizeof(len));

	if ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == 	IEEE154_TYPE_DATA) {	
		dbg("Radio", "capeRadio RadioReceive.receive(0x%1x, 0x%1x, %d )", msg, payload, len);
		bufferPointer = signal RadioReceive.receive(bufferPointer, payload, len);
	}
}

event bool Model.shouldAck(message_t* msg) {
	fennec_header_t *header;
	header = (fennec_header_t*)call RadioPacket.getPayload(bufferPointer,
						sizeof(fennec_header_t));

	if ( (header->dest == TOS_NODE_ID) && (header->fcf & (1 << IEEE154_FCF_ACK_REQ)) ) {  	
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




















async command bool RadioLinkPacketMetadata.highChannelQuality(message_t* msg) {
        return call PacketLinkQuality.get(msg) > 105;
}

async command error_t RadioCCA.request() {
        //if (call PacketIndicator.isReceiving()) {
//                signal RadioCCA.done(EBUSY);
//                return EBUSY;
        //}

        //if (call CCA.get()) {
                signal RadioCCA.done(SUCCESS);
                return SUCCESS;
        //}
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

