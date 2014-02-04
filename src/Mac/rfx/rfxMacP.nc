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
  * Fennec Fox empty MAC layer.
  *
  * @author: Marcin K Szczodrak
  */

#include <Fennec.h>
#include "rfxMac.h"

module rfxMacP @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface rfxMacParams;
uses interface RadioBuffer;
uses interface RadioPacket;
uses interface RadioSend;

uses interface SplitControl as RadioControl;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface RadioReceive;

uses interface Random;
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as PacketIndicator;

uses interface State as SplitControlState;

uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;
uses interface RadioCCA;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;


/* Active Message */

uses interface AMPacket as ActiveMessageLayerAMPacket;
uses interface Packet as ActiveMessageLayerPacket;
uses interface AMSend as ActiveMessageLayerAMSend;
uses interface Receive as ActiveMessageLayerReceive;
uses interface Receive as ActiveMessageLayerSnoop;

//provides interface RadioState as ActiveMessageLayerRadioState;
provides interface RadioPacket as ActiveMessageLayerRadioPacket;
provides interface BareReceive as ActiveMessageLayerBareReceive;
provides interface BareSend as ActiveMessageLayerBareSend;
provides interface ActiveMessageConfig as ActiveMessageLayerActiveMessageConfig;


uses interface Ieee154PacketLayer;

}

implementation {

rfx_mac_header_t* getHeader(message_t *m) {
	uint8_t *p = (uint8_t*)(m->data);
	return (rfx_mac_header_t*)(p + call RadioPacket.headerLength(m));
}


/* Functions */

command error_t SplitControl.start() {
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}


command error_t SplitControl.stop() {
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}



event void RadioControl.startDone(error_t err) {
//	dbg("Mac", "rfxMac RadioControl.startDone(%d)", err);
}


event void RadioControl.stopDone(error_t err) {
//	dbg("Mac", "rfxMac RadioControl.stopDone(%d)", err);
} 


command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	return call ActiveMessageLayerAMSend.send(addr, msg, len);
}

command error_t MacAMSend.cancel(message_t* msg) {
	dbg("Mac", "rfxMac MacAMSend.cancel(0x%1x)", msg);
	return call ActiveMessageLayerAMSend.cancel(msg);
}

command uint8_t MacAMSend.maxPayloadLength() {
	dbg("Mac", "rfxMac MacAMSend.maxPayloadLength()");
	return call ActiveMessageLayerAMSend.maxPayloadLength();
}

command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac", "rfxMac MacAMSend.getpayload(0x%1x, %d )", msg, len);
	return call ActiveMessageLayerAMSend.getPayload(msg, len);
}

/***************** PacketAcknowledgement Commands ****************/
async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
	rfx_mac_header_t* header = getHeader(p_msg);
	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
	rfx_mac_header_t* header = getHeader(p_msg);
	header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	return SUCCESS;
}

async command bool MacPacketAcknowledgements.wasAcked( message_t* p_msg ) {
	metadata_t* metadata = (metadata_t*) p_msg->metadata;
	return metadata->ack;
}

event void RadioConfig.syncDone(error_t error) {
}

async event void RadioPower.startVRegDone() {
}

async event void RadioPower.startOscillatorDone() {
}

event void ReadRssi.readDone(error_t error, uint16_t rssi) {
}

event void RadioResource.granted() {
}

/***************** AMPacket Commands ****************/
command am_addr_t MacAMPacket.address() {
	return TOS_NODE_ID;
}

command am_addr_t MacAMPacket.destination(message_t* amsg) {
	return getHeader(amsg)->dest;
}

command am_addr_t MacAMPacket.source(message_t* amsg) {
	return getHeader(amsg)->src;
}

command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	getHeader(amsg)->dest = addr;
}

command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	getHeader(amsg)->src = addr;
}

command bool MacAMPacket.isForMe(message_t* amsg) {
	return (call MacAMPacket.destination(amsg) == call MacAMPacket.address() ||
		call MacAMPacket.destination(amsg) == AM_BROADCAST_ADDR);
}

command am_id_t MacAMPacket.type(message_t* amsg) {
	return UNKNOWN;
}

command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
}

command am_group_t MacAMPacket.group(message_t* amsg) {
	return getHeader(amsg)->destpan;
}

command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	getHeader(amsg)->destpan = grp;
	// Overridden intentionally when we send()
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
	return call RadioPacket.payloadLength(msg) - sizeof(rfx_mac_header_t);
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
	call RadioPacket.setPayloadLength(msg, len + sizeof(rfx_mac_header_t));
}

command uint8_t MacPacket.maxPayloadLength() {
	return call RadioPacket.maxPayloadLength() - sizeof(rfx_mac_header_t);
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	if (len <= call MacPacket.maxPayloadLength()) {
		uint8_t *p = (uint8_t*) getHeader(msg);
		return (p + sizeof(rfx_mac_header_t));
	} else {
		return NULL;
	}
}


async event message_t* RadioReceive.receive(message_t* msg) {
	return signal ActiveMessageLayerBareReceive.receive(msg);
}

async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
	dbg("Mac", "rfxMac MacAMSend.loadDone(0x%1x, %d )", msg, error);
}


async event void RadioSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "rfxMac MacAMSend.sendDone(0x%1x, %d )", msg, error);
}

event void RadioState.done() {}


async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call RadioLinkPacketMetadata.highChannelQuality(msg);
}

async event void RadioSend.ready() {

}

async event void RadioCCA.done(error_t err) {

}

async event bool RadioReceive.header(message_t* msg) {
        return TRUE;
}














/*----------------- ActiveMessageLayerActiveMessageConfig -----------------*/

        command am_addr_t ActiveMessageLayerActiveMessageConfig.destination(message_t* msg)
        {
                return call Ieee154PacketLayer.getDestAddr(msg);
        }

        command void ActiveMessageLayerActiveMessageConfig.setDestination(message_t* msg, am_addr_t addr)
        {
                call Ieee154PacketLayer.setDestAddr(msg, addr);
        }

        command am_addr_t ActiveMessageLayerActiveMessageConfig.source(message_t* msg)
        {
                return call Ieee154PacketLayer.getSrcAddr(msg);
        }

        command void ActiveMessageLayerActiveMessageConfig.setSource(message_t* msg, am_addr_t addr)
        {
                call Ieee154PacketLayer.setSrcAddr(msg, addr);
        }

        command am_group_t ActiveMessageLayerActiveMessageConfig.group(message_t* msg)
        {
                return call Ieee154PacketLayer.getDestPan(msg);
        }

        command void ActiveMessageLayerActiveMessageConfig.setGroup(message_t* msg, am_group_t grp)
        {
                call Ieee154PacketLayer.setDestPan(msg, grp);
        }

        command error_t ActiveMessageLayerActiveMessageConfig.checkFrame(message_t* msg)
        {
                if( ! call Ieee154PacketLayer.isDataFrame(msg) )
                        call Ieee154PacketLayer.createDataFrame(msg);

                return SUCCESS;
        }




async command uint8_t ActiveMessageLayerRadioPacket.maxPayloadLength() {
        dbg("Radio", "nullRadio RadioBuffer.maxPayloadLength()");
	return call RadioPacket.maxPayloadLength();
}

async command uint8_t ActiveMessageLayerRadioPacket.headerLength(message_t* msg) {
	return call RadioPacket.headerLength(msg);
}

async command uint8_t ActiveMessageLayerRadioPacket.payloadLength(message_t* msg) {
	return call RadioPacket.payloadLength(msg);
}

async command void ActiveMessageLayerRadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	return call RadioPacket.setPayloadLength(msg, length);
}

async command uint8_t ActiveMessageLayerRadioPacket.metadataLength(message_t* msg) {
	return call RadioPacket.metadataLength(msg);
}

async command void ActiveMessageLayerRadioPacket.clear(message_t* msg) {
	return call RadioPacket.clear(msg);
}





}

