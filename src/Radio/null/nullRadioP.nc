/*
 *  null radio module for Fennec Fox platform.
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
 * Network: null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "nullRadio.h"
#include "CC2420TimeSyncMessage.h"

module nullRadioP @safe() {
provides interface SplitControl;
provides interface RadioReceive;
provides interface Resource as RadioResource;
provides interface RadioConfig;
provides interface RadioPower;
provides interface Read<uint16_t> as ReadRssi;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;
provides interface ReceiveIndicator as PacketIndicator;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

uses interface nullRadioParams;

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
	dbg("Radio", "nullRadio SplitControl.start()");

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
	dbg("Radio", "nullRadio SplitControl.stop()");
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

command error_t RadioState.setChannel(uint8_t ch) {
        call RadioConfig.setChannel( ch );
	signal RadioState.done();
        return SUCCESS;
}

command uint8_t RadioState.getChannel() {
        return call RadioConfig.getChannel();
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

async command error_t RadioCCA.request() {
	return SUCCESS;
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

task void load_done() {
	signal RadioBuffer.loadDone(m, SUCCESS);
}

async command error_t RadioBuffer.load(message_t* msg) {
	dbg("Radio", "nullRadio RadioBuffer.load(0x%1x)", msg);
	m = msg;
	post load_done();
	return SUCCESS;
}

task void send_done() {
	signal RadioSend.sendDone(m, SUCCESS);
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	dbg("Radio", "nullRadio RadioBuffer.send(0x%1x)", msg, useCca);
	post send_done();
	return SUCCESS;
}

async command uint8_t RadioPacket.maxPayloadLength() {
	dbg("Radio", "nullRadio RadioBuffer.maxPayloadLength()");
	return NULL_MAX_MESSAGE_SIZE - sizeof(nx_struct null_radio_header_t) - NULL_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	return sizeof(nx_struct null_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct null_radio_header_t *hdr = (nx_struct null_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct null_radio_header_t) - NULL_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct null_radio_header_t *hdr = (nx_struct null_radio_header_t*)(msg->data);
	hdr->length = length + sizeof(nx_struct null_radio_header_t) + NULL_SIZEOF_CRC + sizeof(timesync_radio_t);
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

