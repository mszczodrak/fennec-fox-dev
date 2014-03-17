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
  * Fennec Fox cape radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */

#include "cape.h"

module capeMultiP {
provides interface RadioReceive[process_t process];
provides interface RadioSend[process_t process];
provides interface RadioBuffer[process_t process];
provides interface RadioState[process_t process];
provides interface RadioCCA[process_t process];

uses interface RadioReceive as SubRadioReceive;
uses interface RadioSend as SubRadioSend;
uses interface RadioBuffer as SubRadioBuffer;
uses interface RadioState as SubRadioState;
uses interface RadioCCA as SubRadioCCA;
}

implementation {

norace process_t last_proc_id = UNKNOWN;
norace process_t last_proc_id_state = UNKNOWN;
norace process_t last_proc_id_cca = UNKNOWN;

process_t getProcessId(message_t *msg) {
	cape_hdr_t* header = (cape_hdr_t*)(msg->data);
	last_proc_id = header->destpan;
	return header->destpan;
}

void setProcessId(message_t *msg, process_t process) {
	cape_hdr_t* header = (cape_hdr_t*)(msg->data);
	last_proc_id = process;
	header->destpan = process;
}

event void SubRadioState.done() {
	signal RadioState.done[last_proc_id_state]();
}

command error_t RadioState.turnOff[process_t process]() {
	dbg("Radio", "[%d] cape RadioState.turnOff()", process);
	last_proc_id_state = process;
	return call SubRadioState.turnOff();
}

command error_t RadioState.turnOn[process_t process]() {
	dbg("Radio", "[%d] cape RadioState.turnOn()", process);
	last_proc_id_state = process;
	return call SubRadioState.turnOn();
}

command error_t RadioState.standby[process_t process]() {
	dbg("Radio", "[%d] cape RadioState.standby()", process);
	last_proc_id_state = process;
	return call SubRadioState.turnOff();
}

command error_t RadioState.setChannel[process_t process](uint8_t channel) {
	dbg("Radio", "[%d] cape RadioState.setChannel(%d)", process, channel);
	last_proc_id_state = process;
	return call SubRadioState.setChannel( channel );
}

command uint8_t RadioState.getChannel[process_t process]() {
	dbg("Radio", "[%d] cape RadioState.getChannel()", process);
	last_proc_id_state = process;
        return call SubRadioState.getChannel();
}

async command error_t RadioBuffer.load[process_t process](message_t* msg) {
	dbg("Radio", "[%d] cape RadioBuffer.load(0x%1x)", process, msg);
	setProcessId(msg, process);
	return call SubRadioBuffer.load(msg);
}

async command error_t RadioSend.send[process_t process](message_t* msg, bool useCca) {
	dbg("Radio", "[%d] cape RadioSend.send(0x%1x, %d)", process, msg, useCca);
	setProcessId(msg, process);
	return call SubRadioSend.send(msg, useCca);
}

async command error_t RadioCCA.request[process_t process]() {
	//dbg("Radio", "[%d] cape RadioCCA.request()", process);
	last_proc_id_cca = process;
	return call SubRadioCCA.request();
}

async event void SubRadioBuffer.loadDone(message_t *msg, error_t err) {
	dbg("Radio", "[%d] cape signal RadioBuffer.loadDone(0x%1x, %d)",
			getProcessId(msg), msg, err);
	signal RadioBuffer.loadDone[getProcessId(msg)](msg, err);
}

async event bool SubRadioReceive.header(message_t* msg) {
	if (validProcessId(getProcessId(msg))) {
		dbg("Radio", "[%d] cape SubRadioReceive.header(0x%1x)",
				getProcessId(msg), msg);
		return signal RadioReceive.header[getProcessId(msg)](msg);
	} else {
		dbg("Radio", "[%d] cape SubRadioReceive.header(0x%1x) - not valid",
				getProcessId(msg), msg);
		return FAIL;
	}
}

async event message_t *SubRadioReceive.receive(message_t* msg) {
	if (validProcessId(getProcessId(msg))) {
		dbg("Radio", "[%d] cape SubRadioReceive.receive(0x%1x)",
				getProcessId(msg), msg);
		return signal RadioReceive.receive[getProcessId(msg)](msg);
	} else {
		dbg("Radio", "[%d] cape SubRadioReceive.receive(0x%1x) - not valid",
				getProcessId(msg), msg);
		return msg;
	}
}

async event void SubRadioSend.ready() {
        signal RadioSend.ready[last_proc_id]();
}

async event void SubRadioSend.sendDone(message_t *msg, error_t error) {
	if (validProcessId(getProcessId(msg))) {
		dbg("Radio", "[%d] cape SubRadioSend.sendDone(0x%1x, %d)", 
				getProcessId(msg), msg, error);
		return signal RadioSend.sendDone[getProcessId(msg)](msg, error);
	} else {
		dbg("Radio", "[%d] cape SubRadioSend.sendDone(0x%1x, %d) - not valid", 
				getProcessId(msg), msg, error);
	}
}

async event void SubRadioCCA.done(error_t error) {
	//dbg("Radio", "[%d] SubRadioCCA.done(%d)", last_proc_id_cca, error);
	signal RadioCCA.done[last_proc_id_cca](error);
}

default async event bool RadioReceive.header[process_t process](message_t* msg) {
	return FALSE;
}

default async event message_t * RadioReceive.receive[process_t process](message_t* msg) {
	return msg;
}

default async event void RadioSend.sendDone[process_t process](message_t* msg, error_t error) {

}

default async event void RadioSend.ready[process_t process]() {

}

default async event void RadioBuffer.loadDone[process_t process](message_t *msg, error_t error) {

}

default event void RadioState.done[process_t process]() {

}

default async event void RadioCCA.done[process_t process](error_t error) {

}

}
