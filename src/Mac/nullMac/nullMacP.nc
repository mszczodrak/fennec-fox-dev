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
#include "nullMac.h"

generic module nullMacP() @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface nullMacParams;
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
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;
}

implementation {

uint8_t status = S_STOPPED;
norace message_t * ONE_NOK m_msg;
norace message_t * ONE_NOK r_msg;
norace message_t * ONE_NOK r_msg_ptr;
norace uint8_t m_state = S_STOPPED;

error_t sendErr = SUCCESS;

norace message_t receiveQueueData[NULL_MAC_RECEIVE_QUEUE_SIZE];
norace message_t* receiveQueue[NULL_MAC_RECEIVE_QUEUE_SIZE];

norace uint8_t receiveQueueHead;
norace uint8_t receiveQueueSize;

/****************** Prototypes ****************/
task void startDone_task();
task void stopDone_task();
task void sendDone_task();

task void startDone_task() {
	uint8_t i;
	for(i = 0; i < NULL_MAC_RECEIVE_QUEUE_SIZE; ++i) {
		receiveQueue[i] = receiveQueueData + i;
	}

	m_state = S_STARTED;
	call SplitControlState.forceState(S_STARTED);
}

task void stopDone_task() {
	call SplitControlState.forceState(S_STOPPED);
}

void shutdown() {
	m_state = S_STOPPED;
	post stopDone_task();
}

null_mac_header_t* getHeader(message_t *m) {
	uint8_t *p = (uint8_t*)(m->data);
	return (null_mac_header_t*)(p + call RadioPacket.headerLength(m));
}

error_t SplitControl_start() {

	if(call SplitControlState.requestState(S_STARTING) == SUCCESS) {
		call RadioControl.start();
		return SUCCESS;
	} else if(call SplitControlState.isState(S_STARTED)) {
		return EALREADY;
	} else if(call SplitControlState.isState(S_STARTING)) {
		return SUCCESS;
	}
	return EBUSY;
}

error_t SplitControl_stop() {
	if (call SplitControlState.isState(S_STARTED)) {
		call SplitControlState.forceState(S_STOPPING);
		call RadioControl.stop();
		return SUCCESS;	
	} else if(call SplitControlState.isState(S_STOPPED)) {
		return EALREADY;
	} else if(call SplitControlState.isState(S_TRANSMITTING)) {
		call SplitControlState.forceState(S_STOPPING);
		// At sendDone, the radio will shut down
		return SUCCESS;
	} else if(call SplitControlState.isState(S_STOPPING)) {
		return SUCCESS;
	}
	return EBUSY;
}


/* Functions */

command error_t SplitControl.start() {
	dbg("Mac", "nullMac SplitControl.start()");
	post startDone_task();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("Mac", "nullMac SplitControl.stop()");
	shutdown();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}



event void RadioControl.startDone(error_t err) {
//	dbg("Mac", "nullMac RadioControl.startDone(%d)", err);
}


event void RadioControl.stopDone(error_t err) {
//	dbg("Mac", "nullMac RadioControl.stopDone(%d)", err);
} 


command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	null_mac_header_t* header;

	dbg("Mac", "nullMac MacAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	header = getHeader(msg);

	getMetadata(msg)->crc = 0;
	getMetadata(msg)->rssi = 0;
	getMetadata(msg)->lqi = 0;
	getMetadata(msg)->ack = 1;

	if (len > call MacPacket.maxPayloadLength()) {
		return ESIZE;
	}

	header->dest = addr;
	header->src = call MacAMPacket.address();
	header->fcf |= ( 1 << IEEE154_FCF_INTRAPAN ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;

	call MacPacket.setPayloadLength(msg, len);

	if (header->fcf & 1 << IEEE154_FCF_ACK_REQ) {
		header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	}

	atomic {
		if (!call SplitControlState.isState(S_STARTED)) {
			return FAIL;
		}

		call SplitControlState.forceState(S_TRANSMITTING);
		m_msg = msg;
	}


	header->fcf &= ((1 << IEEE154_FCF_ACK_REQ) |
		(0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
		(0x3 << IEEE154_FCF_DEST_ADDR_MODE));
	header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
		( 1 << IEEE154_FCF_INTRAPAN ) );

	if ( m_state != S_STARTED ) {
		return FAIL;
	}


	m_state = S_LOAD;

	call RadioBuffer.load(m_msg);
	return SUCCESS;
}

command error_t MacAMSend.cancel(message_t* msg) {
	dbg("Mac", "nullMac MacAMSend.cancel(0x%1x)", msg);
	m_state = S_STARTED;
}

command uint8_t MacAMSend.maxPayloadLength() {
	dbg("Mac", "nullMac MacAMSend.maxPayloadLength()");
	return call MacPacket.maxPayloadLength();
}

command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac", "nullMac MacAMSend.getpayload(0x%1x, %d )", msg, len);
	return call MacPacket.getPayload(msg, len);
}

/***************** PacketAcknowledgement Commands ****************/
async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
	null_mac_header_t* header = getHeader(p_msg);
	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
	null_mac_header_t* header = getHeader(p_msg);
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
	return call RadioPacket.payloadLength(msg) - sizeof(null_mac_header_t);
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
	call RadioPacket.setPayloadLength(msg, len + sizeof(null_mac_header_t));
}

command uint8_t MacPacket.maxPayloadLength() {
	return call RadioPacket.maxPayloadLength() - sizeof(null_mac_header_t);
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	if (len <= call MacPacket.maxPayloadLength()) {
		uint8_t *p = (uint8_t*) getHeader(msg);
		return (p + sizeof(null_mac_header_t));
	} else {
		return NULL;
	}
}

task void sendDone_task() {
	error_t packetErr;
	atomic packetErr = sendErr;
	if(call SplitControlState.isState(S_STOPPING)) {
		shutdown();
	} else {
		call SplitControlState.forceState(S_STARTED);
	}
	signal MacAMSend.sendDone( m_msg, packetErr );
}

task void deliverTask() {
        // get rid of as many messages as possible without interveining tasks
        message_t* msg;
        uint8_t *p;
	uint8_t len;

	atomic {
		if( receiveQueueSize == 0 ) {
			return;
		}

		msg = receiveQueue[receiveQueueHead];
		p = (uint8_t*)(msg->data);
		p += (call RadioPacket.headerLength(msg) + sizeof(null_mac_header_t));
		len = (call RadioPacket.payloadLength(msg) - sizeof(null_mac_header_t));
	}

	if (call MacAMPacket.isForMe(msg)) {
		dbg("Mac", "nullMac MacReceive.receive(0x%1x, 0x%1x, %d )", msg, p, len);
		msg = signal MacReceive.receive(msg, p, len);
	} else {
		dbg("Mac", "nullMac MacSnoop.receive(0x%1x, 0x%1x, %d )", msg, p, len);
		msg = signal MacSnoop.receive(msg, p, len);
	}

	atomic {
		call RadioPacket.clear(msg);
		receiveQueue[receiveQueueHead] = msg;
		if( ++receiveQueueHead >= NULL_MAC_RECEIVE_QUEUE_SIZE )
			receiveQueueHead = 0;

		--receiveQueueSize;
	}
	post deliverTask();
}



async event message_t* RadioReceive.receive(message_t* msg) {
	message_t *m;
	if(!(getMetadata(msg))->crc) {
		dbg("Mac", "nullMac MacAMSend.receive did not pass CRC");
		return msg;
	}

	dbg("Mac", "nullMac RadioReceive.receive(0x%1x)", msg);
	atomic {
		if( receiveQueueSize >= NULL_MAC_RECEIVE_QUEUE_SIZE ) {
			m = msg;
		} else {
			uint8_t idx = receiveQueueHead + receiveQueueSize;
			if( idx >= NULL_MAC_RECEIVE_QUEUE_SIZE )
				idx -= NULL_MAC_RECEIVE_QUEUE_SIZE;

			m = receiveQueue[idx];
			receiveQueue[idx] = msg;

			++receiveQueueSize;
			post deliverTask();
		}
	}
	return m;
}

async event bool RadioReceive.header(message_t* msg) {
	return receiveQueueSize < NULL_MAC_RECEIVE_QUEUE_SIZE;
	//return TRUE;
}

async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
	dbg("Mac", "nullMac MacAMSend.loadDone(0x%1x, %d )", msg, error);
	m_state = S_BEGIN_TRANSMIT;
	call RadioSend.send(m_msg, 0);
}


async event void RadioSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "nullMac MacAMSend.sendDone(0x%1x, %d )", msg, error);
	m_state = S_STARTED;
	atomic sendErr = error;
	post sendDone_task();
}

event void RadioState.done() {}


async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call RadioLinkPacketMetadata.highChannelQuality(msg);
}

async event void RadioSend.ready() {

}

async event void RadioCCA.done(error_t err) {

}



}

