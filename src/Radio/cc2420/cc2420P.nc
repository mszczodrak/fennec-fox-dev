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
  * cc2420 driver adapted from the TinyOS ActiveMessage stack for CC2420 and cc2420x
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include "cc2420.h"

generic module cc2420P(process_t process_id) @safe() {
provides interface SplitControl;
provides interface RadioState;
provides interface Resource as RadioResource;

uses interface Leds;
uses interface cc2420Params;
uses interface RadioState as SubRadioState;
uses interface cc2420DriverParams;
uses interface Resource as SubRadioResource;

}

implementation {

norace uint8_t state = S_STOPPED;
norace error_t err;
bool sc = FALSE;

task void set_params() {
	call cc2420DriverParams.set_power( call cc2420Params.get_power() );
	call cc2420DriverParams.set_channel( call cc2420Params.get_channel() );
	call cc2420DriverParams.set_ack( call cc2420Params.get_ack() );
	call cc2420DriverParams.set_crc( call cc2420Params.get_crc() );
}

event void SubRadioState.done() {
	//printf("SubRadioState.done() - [%d]\n", process_id);
	signal RadioState.done();
	if (sc != TRUE) {
		return;
	}

	if (state == S_STARTING) {
		post set_params();
		state = S_STARTED;
		//printf("SplitControl.startDone(SUCCESS) - [%d]\n", process_id);
		signal SplitControl.startDone(SUCCESS);
	}

	if (state == S_STOPPING) {
		state = S_STOPPED;
		//printf("SplitControl.stopDone(SUCCESS) - [%d]\n", process_id);
		signal SplitControl.stopDone(SUCCESS);
	}
	sc = FALSE;
}
		
command error_t SplitControl.start() {
	sc = TRUE;
	//printf("SplitControl.start() - [%d]\n", process_id);
	post set_params();
	state = S_STARTING;
	call SubRadioResource.release();
	return call SubRadioState.turnOn();
}


command error_t SplitControl.stop() {
	sc = TRUE;
	//printf("SplitControl.stop() - [%d]\n", process_id);
	state = S_STOPPING;
	return call SubRadioState.turnOff();
}

command error_t RadioState.turnOn() {
	return call SubRadioState.turnOn();
}

command error_t RadioState.turnOff() {
	return call SubRadioState.turnOff();
}

command error_t RadioState.standby() {
	return call SubRadioState.standby();
}

command error_t RadioState.setChannel(uint8_t channel) {
	return call SubRadioState.setChannel(channel);
}

command error_t RadioState.getChannel() {
	return call SubRadioState.getChannel();
}

async command error_t RadioResource.immediateRequest() {
	return call SubRadioResource.immediateRequest();
}

async command error_t RadioResource.request() {
	return call SubRadioResource.request();
}

async command bool RadioResource.isOwner() {
	return call SubRadioResource.isOwner();
}

async command error_t RadioResource.release() {
	return call SubRadioResource.release();
}

event void SubRadioResource.granted() {
	signal RadioResource.granted();
}

}

