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
  * Fennec Fox rf212 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/10/2014
  */

#include <Fennec.h>
#include "rf212.h"

module rf212P @safe() {
provides interface SplitControl;
provides interface RadioReceive;
provides interface RadioBuffer;
provides interface RadioSend;
provides interface RadioState;

uses interface rf212Params;

uses interface RadioState as SubRadioState;
uses interface RadioReceive as SubRadioReceive;
uses interface RadioSend as SubRadioSend;
uses interface RadioPacket;

}

implementation {

norace uint8_t state = S_STOPPED;
norace message_t *m;
bool sc = FALSE;
norace error_t err;

task void start_done() {
	if (err == SUCCESS) {
        	state = S_STARTED;
	}
	signal RadioState.done();
	if (sc == TRUE) {
                signal SplitControl.startDone(err);
                sc = FALSE;
        }
}

task void stop_done() {
	if (err == SUCCESS) {
		state = S_STOPPED;
	}
	signal RadioState.done();
	if (sc == TRUE) {
		signal SplitControl.stopDone(err);
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
	state = S_STARTING;
	if (call SubRadioState.turnOn() != SUCCESS) {
		signal SubRadioState.done();
	}
	return SUCCESS;
}

command error_t RadioState.turnOff() {
	state = S_STOPPING;
	if (call SubRadioState.turnOff() != SUCCESS) {
		signal SubRadioState.done();
	}
	return SUCCESS;
}

command error_t RadioState.standby() {
        return call RadioState.turnOff();
}

command error_t RadioState.setChannel(uint8_t channel) {
        return call SubRadioState.setChannel( channel );
}

command uint8_t RadioState.getChannel() {
        return call SubRadioState.getChannel();
}

event void SubRadioState.done() {
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


task void load_done() {
	signal RadioBuffer.loadDone(m, SUCCESS);
}

async command error_t RadioBuffer.load(message_t* msg) {
	rf212_hdr_t* header = (rf212_hdr_t*)(msg->data);
	header->destpan = msg->conf;
	signal RadioBuffer.loadDone(msg, SUCCESS);
	return SUCCESS;
}

task void send_done() {
	signal RadioSend.sendDone(m, SUCCESS);
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	dbg("Radio", "rf212 RadioBuffer.send(0x%1x)", msg, useCca);
	return call SubRadioSend.send(msg, useCca);
}

async event void SubRadioSend.ready() {
	signal RadioSend.ready();
}

async event void SubRadioSend.sendDone(message_t *msg, error_t error) {
	m = msg;
	signal RadioSend.sendDone(msg, error);
}


async event bool SubRadioReceive.header(message_t* msg) {
	rf212_hdr_t* header = (rf212_hdr_t*)(msg->data);
	msg->conf = header->destpan;
	return signal RadioReceive.header(msg);
}


async event message_t *SubRadioReceive.receive(message_t* msg) {
	rf212_hdr_t* header = (rf212_hdr_t*)(msg->data);
	msg->conf = header->destpan;
	return signal RadioReceive.receive(msg);
}


}

