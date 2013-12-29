/*
 *  cu MAC module for Fennec Fox platform.
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
 * Module: cu MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
//#include <Ieee154.h> 
#include "cuMac.h"

module cuMacP @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface cuMacParams;
uses interface RadioBuffer;
uses interface RadioPacket;
uses interface RadioSend;

uses interface SplitControl as RadioControl;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface Receive as RadioReceive;

uses interface Random;
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as PacketIndicator;

uses interface RadioState;
uses interface LinkPacketMetadata;

uses interface State as SplitControlState;
}

implementation {

uint8_t status = S_STOPPED;
norace message_t * ONE_NOK m_msg;
norace uint8_t m_state = S_STOPPED;

enum {
	S_STOPPED,
	S_STARTING,
	S_STARTED,
	S_STOPPING,
	S_TRANSMITTING,
};

error_t sendErr = SUCCESS;

/****************** Prototypes ****************/
task void startDone_task();
task void stopDone_task();
task void sendDone_task();

task void startDone_task() {
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
	dbg("Mac", "cuMac SplitControl.start()");
	post startDone_task();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("Mac", "cuMac SplitControl.stop()");
	shutdown();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}



event void RadioControl.startDone(error_t err) {
//	dbg("Mac", "cuMac RadioControl.startDone(%d)", err);
}


event void RadioControl.stopDone(error_t err) {
//	dbg("Mac", "cuMac RadioControl.stopDone(%d)", err);
} 


command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	fennec_header_t* header;
	metadata_t* metadata;

	dbg("Mac", "cuMac MacAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	header = (fennec_header_t*)call RadioPacket.getPayload( msg, len);
	metadata = (metadata_t*) msg->metadata;
	call MacAMPacket.setGroup(msg, msg->conf);

	msg->crc = 0;
	msg->rssi = 0;
	msg->lqi = 0;

	if (len > call MacPacket.maxPayloadLength()) {
		return ESIZE;
	}

	header->dest = addr;
	header->src = call MacAMPacket.address();
	header->fcf |= ( 1 << IEEE154_FCF_INTRAPAN ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;
	header->length = len + sizeof(fennec_header_t);


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

//        header->fcf |= ( ( IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE ) |
//                     ( 1 << IEEE154_FCF_INTRAPAN ) );


//	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;

	header->dsn = 20;

	/* Fennec Fox bit */
	header->fcf |= 1 << IEEE154_FCF_RESERVED;

	if (header->fcf & 1 << IEEE154_FCF_ACK_REQ) {
		header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	}

	metadata->ack = 1;
	metadata->rssi = 0;
	metadata->lqi = 0;
	metadata->timestamp = NULL_INVALID_TIMESTAMP;

	if ( m_state != S_STARTED ) {
		return FAIL;
	}


	m_state = S_LOAD;
	m_msg = m_msg;

	call RadioBuffer.load(m_msg);
	return SUCCESS;
}

command error_t MacAMSend.cancel(message_t* msg) {
	dbg("Mac", "cuMac MacAMSend.cancel(0x%1x)", msg);
	return call RadioSend.cancel(msg);
}

command uint8_t MacAMSend.maxPayloadLength() {
	dbg("Mac", "cuMac MacAMSend.maxPayloadLength()");
	return call MacPacket.maxPayloadLength();
}

command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac", "cuMac MacAMSend.getpayload(0x%1x, %d )", msg, len);
	return call MacPacket.getPayload(msg, len);
}

/***************** PacketAcknowledgement Commands ****************/
async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(p_msg, sizeof(fennec_header_t));
	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(p_msg, sizeof(fennec_header_t));
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
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	return header->dest;
}

command am_addr_t MacAMPacket.source(message_t* amsg) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	return header->src;
}

command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	header->dest = addr;
}

command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	header->src = addr;
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
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	return header->destpan;
}

command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	// Overridden intentionally when we send()
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(amsg, sizeof(fennec_header_t));
	header->destpan = grp;
}

command am_group_t MacAMPacket.localGroup() {
	return 0;
//    return call CC2420Config.getPanAddr();
}


/***************** Packet Commands ****************/
command void MacPacket.clear(message_t* msg) {
	metadata_t* metadata = (metadata_t*) msg->metadata;
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(msg, sizeof(fennec_header_t));
	memset(header, 0x0, sizeof(fennec_header_t));
	memset(metadata, 0x0, sizeof(metadata_t));
}

command uint8_t MacPacket.payloadLength(message_t* msg) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(msg, sizeof(fennec_header_t));
	return header->length - sizeof(fennec_header_t);
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
	fennec_header_t* header = (fennec_header_t*)call RadioPacket.getPayload(msg, sizeof(fennec_header_t));
	header->length  = len + sizeof(fennec_header_t);
}

command uint8_t MacPacket.maxPayloadLength() {
	return (call RadioPacket.maxPayloadLength() - sizeof(fennec_header_t));
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	if (len <= call MacPacket.maxPayloadLength()) {
		uint8_t *p = call RadioPacket.getPayload(msg, len);
		return (p + sizeof(fennec_header_t));
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

event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len) {
	metadata_t* metadata = (metadata_t*) msg->metadata;
	uint8_t *ptr = (uint8_t*) payload;
	fennec_header_t *header = (fennec_header_t*) payload;
	uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;

/*
	if ( type == IEEE154_TYPE_ACK ) {
		printf("receive\n");
		printfflush();
	} else {
		printf("receive ack\n");
		printfflush();
	}
*/
	
	if(!(metadata)->crc) {
		dbg("Mac", "cuMac MacAMSend.receive did not pass CRC");
		return msg;
	}

//    msg->conf = call MacAMPacket.group(msg);
//    msg->conf = call MacAMPacket.group(msg);

	msg->rssi = metadata->rssi;
	msg->lqi = metadata->lqi;
	msg->crc = metadata->crc;

	if (call MacAMPacket.isForMe(msg)) {
	        dbg("Mac", "cuMac MacReceive.receive(0x%1x, 0x%1x, %d )", msg,
                        ptr + sizeof(fennec_header_t),
                        len - sizeof(fennec_header_t));
        	return signal MacReceive.receive(msg,
                        ptr + sizeof(fennec_header_t),
                        len - sizeof(fennec_header_t));
	} else {
		dbg("Mac", "cuMac MacSnoop.receive(0x%1x, 0x%1x, %d )", msg,
			ptr + sizeof(fennec_header_t),
			len - sizeof(fennec_header_t));
		return signal MacSnoop.receive(msg,
			ptr + sizeof(fennec_header_t),
			len - sizeof(fennec_header_t));
	}
}

async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
	dbg("Mac", "cuMac MacAMSend.loadDone(0x%1x, %d )", msg, error);
	m_state = S_BEGIN_TRANSMIT;
	call RadioSend.send(m_msg, 0);
}


async event void RadioSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "cuMac MacAMSend.sendDone(0x%1x, %d )", msg, error);
	m_state = S_STARTED;
	atomic sendErr = error;
	post sendDone_task();

}

event void RadioState.done() {}


}

