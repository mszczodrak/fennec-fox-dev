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
  * Fennec Fox cc2420 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */

module cc2420MultiP {
provides interface RadioReceive[uint8_t process_id];
provides interface RadioSend[uint8_t process_id];
provides interface RadioBuffer[uint8_t process_id];
provides interface RadioState[uint8_t process_id];

uses interface RadioReceive as SubRadioReceive;
uses interface RadioSend as SubRadioSend;
uses interface RadioBuffer as SubRadioBuffer;
uses interface RadioState as SubRadioState;
}

implementation {

norace uint8_t last_proc_id;
norace uint8_t last_proc_id_state;

uint8_t getProcessId(message_t *msg) {
	cc2420_hdr_t* header = (cc2420_hdr_t*)(msg->data);
	last_proc_id = header->destpan;
	return header->destpan;
}

void setProcessId(message_t *msg, uint8_t process_id) {
	cc2420_hdr_t* header = (cc2420_hdr_t*)(msg->data);
	last_proc_id = process_id;
	header->destpan = process_id;
}

command error_t RadioState.turnOff[uint8_t process_id]() {
	last_proc_id_state = process_id;
	return call SubRadioState.turnOff();
}

event void SubRadioState.done() {
	signal RadioState.done[last_proc_id_state]();
}

command error_t RadioState.turnOn[uint8_t process_id]() {
	last_proc_id_state = process_id;
	return call SubRadioState.turnOn();
}

command error_t RadioState.standby[uint8_t process_id]() {
	last_proc_id_state = process_id;
	return call SubRadioState.turnOff();
}

command error_t RadioState.setChannel[uint8_t process_id](uint8_t channel) {
	last_proc_id_state = process_id;
	return call SubRadioState.setChannel( channel );
}

command uint8_t RadioState.getChannel[uint8_t process_id]() {
	last_proc_id_state = process_id;
        return call SubRadioState.getChannel();
}

async command error_t RadioBuffer.load[uint8_t process_id](message_t* msg) {
	setProcessId(msg, process_id);
	return call SubRadioBuffer.load(msg);
}

async command error_t RadioSend.send[uint8_t process_id](message_t* msg, bool useCca) {
	setProcessId(msg, process_id);
	return call SubRadioSend.send(msg, useCca);
}

async event void SubRadioBuffer.loadDone(message_t *msg, error_t err) {
	signal RadioBuffer.loadDone[getProcessId(msg)](msg, err);
}

async event bool SubRadioReceive.header(message_t* msg) {
	if (validProcessId(getProcessId(msg))) {
		return signal RadioReceive.header[getProcessId(msg)](msg);
	}
	return FAIL;
}

async event message_t *SubRadioReceive.receive(message_t* msg) {
	return signal RadioReceive.receive[getProcessId(msg)](msg);
}

async event void SubRadioSend.ready() {
        signal RadioSend.ready[last_proc_id]();
}

async event void SubRadioSend.sendDone(message_t *msg, error_t error) {
	return signal RadioSend.sendDone[getProcessId(msg)](msg, error);
}


default async event bool RadioReceive.header[uint8_t process_id](message_t* msg) {
	return FALSE;
}

default async event message_t * RadioReceive.receive[uint8_t process_id](message_t* msg) {
	return msg;
}

default async event void RadioSend.sendDone[uint8_t process_id](message_t* msg, error_t error) {

}

default async event void RadioSend.ready[uint8_t process_id]() {

}

default async event void RadioBuffer.loadDone[uint8_t process_id](message_t *msg, error_t error) {

}

default event void RadioState.done[uint8_t process]() {

}


}
