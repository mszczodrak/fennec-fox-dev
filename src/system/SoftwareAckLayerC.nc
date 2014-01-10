/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

#include <RadioAssert.h>
#include "RFX_IEEE.h"

generic module SoftwareAckLayerC()
{
provides interface RadioSend;
provides interface RadioReceive;
provides interface PacketAcknowledgements;
uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RadioPacket;
uses interface PacketFlag as AckReceivedFlag;
}

implementation {
norace uint8_t state;

enum
{
	STATE_READY = 0,
	STATE_DATA_SEND = 1,
	STATE_ACK_WAIT = 2,
	STATE_ACK_SEND = 3,
};


norace message_t *txMsg;
norace message_t ackMsg;


ieee_radio_hdr_t* getHeader(message_t *msg) {
	return (ieee_radio_hdr_t*)(msg->data);
}

bool isAckPacket(message_t* msg) {
	return (getHeader(msg)->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
}

bool verifyAckReply(message_t* data, message_t* ack) {
	return getHeader(ack)->dsn == getHeader(data)->dsn
		&& (getHeader(ack)->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
}

void setAckRequired(message_t* msg, bool ack) {
	if( ack ) {
		getHeader(msg)->fcf |= (1 << IEEE154_FCF_ACK_REQ);
	} else {
		getHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_ACK_REQ);
	}
}


bool requiresAckWait(message_t* msg) {
	return ( getHeader(msg)->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) &&
		((( getHeader(msg)->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA);
}

bool requiresAckReply(message_t* msg) {
	return ( getHeader(msg)->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) &&
		((( getHeader(msg)->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA) &&
		(getHeader(msg)->dest == TOS_NODE_ID);
}

void createAckReply(message_t* data, message_t* ack) {
	call RadioPacket.setPayloadLength(ack, IEEE154_ACK_FRAME_LENGTH);
	getHeader(ack)->fcf = IEEE154_ACK_FRAME_VALUE;
	getHeader(ack)->dsn = getHeader(data)->dsn;
}


#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT     1000
#endif


uint16_t getAckTimeout() {
	return (uint16_t)(SOFTWAREACK_TIMEOUT * RADIO_ALARM_MICROSEC);
}


async event void SubSend.ready() {
	if( state == STATE_READY )
		signal RadioSend.ready();
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	error_t error;
	if( state == STATE_READY ) {
		if( (error = call SubSend.send(msg, useCca)) == SUCCESS ) {
			call AckReceivedFlag.clear(msg);
			state = STATE_DATA_SEND;
			txMsg = msg;
		}
	} else {
		error = EBUSY;
	}

	return error;
}

async event void SubSend.sendDone(message_t *msg, error_t error) {
	if( state == STATE_ACK_SEND ) {
		// TODO: what if error != SUCCESS
		RADIO_ASSERT( error == SUCCESS );
		state = STATE_READY;
	} else {
		RADIO_ASSERT( state == STATE_DATA_SEND );
		RADIO_ASSERT( call RadioAlarm.isFree() );

		if( error == SUCCESS && requiresAckWait(txMsg) && call RadioAlarm.isFree() ) {
			call RadioAlarm.wait(getAckTimeout());
			state = STATE_ACK_WAIT;
		} else {
			state = STATE_READY;
			signal RadioSend.sendDone(txMsg, error);
		}
	}
}

async event void RadioAlarm.fired() {
	RADIO_ASSERT( state == STATE_ACK_WAIT );

	state = STATE_READY;
	signal RadioSend.sendDone(txMsg, SUCCESS);	// we have sent it, but not acked
}

async event bool SubReceive.header(message_t* msg) {
	// drop unexpected ACKs
	if( isAckPacket(msg) ) {
		return state == STATE_ACK_WAIT;
	}

	// drop packets that need ACKs while waiting for our ACK
//	if( state == STATE_ACK_WAIT && requiresAckWait(msg) )
//		return FALSE;

	return signal RadioReceive.header(msg);
}

async event message_t* SubReceive.receive(message_t* msg) {
	RADIO_ASSERT( state == STATE_ACK_WAIT || state == STATE_READY );

	if( isAckPacket(msg) ) {
		if( state == STATE_ACK_WAIT && verifyAckReply(txMsg, msg) ) {
			call RadioAlarm.cancel();
			call AckReceivedFlag.set(txMsg);

			state = STATE_READY;
			signal RadioSend.sendDone(msg, SUCCESS);
		}
		return msg;
	}

	if( state == STATE_READY && requiresAckReply(msg) ) {
		createAckReply(msg, &ackMsg);

		// TODO: what to do if we are busy and cannot send an ack
		if( call SubSend.send(&ackMsg, FALSE) == SUCCESS )
			state = STATE_ACK_SEND;
		else
			RADIO_ASSERT(FALSE);
	}

	return signal RadioReceive.receive(msg);
}

/*----------------- PacketAcknowledgements -----------------*/

async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
	setAckRequired(msg, TRUE);
	return SUCCESS;
}

async command error_t PacketAcknowledgements.noAck(message_t* msg) {
	setAckRequired(msg, FALSE);
	return SUCCESS;
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return call AckReceivedFlag.get(msg);
}

}
