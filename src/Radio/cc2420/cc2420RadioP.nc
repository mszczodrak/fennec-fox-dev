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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
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
#include "cc2420Radio.h"

module cc2420RadioP @safe() {
provides interface SplitControl;
provides interface RadioState;

uses interface Leds;
uses interface cc2420RadioParams;
uses interface RadioConfig;
uses interface StdControl as ReceiveControl;
uses interface StdControl as TransmitControl;
uses interface RadioPower;
uses interface Resource as RadioResource;
}

implementation {

norace uint8_t state = S_STOPPED;
norace error_t err;
bool sc = FALSE;

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

task void finish_starting_radio() {
	if (call RadioPower.rxOn() != SUCCESS) err = FAIL;
	if (call RadioResource.release() != SUCCESS) err = FAIL;
	if (call ReceiveControl.start() != SUCCESS) err = FAIL;
	if (call TransmitControl.start() != SUCCESS) err = FAIL;
	post start_done();
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

command error_t RadioState.turnOff() {
	err = SUCCESS;

	if (state == S_STOPPED) {
		post stop_done();
		return SUCCESS;
	}

	if (call ReceiveControl.stop() != SUCCESS) err = FAIL;
	if (call TransmitControl.stop() != SUCCESS) err = FAIL;
	if (call RadioPower.stopVReg() != SUCCESS) err = FAIL;

	if (err != SUCCESS) return FAIL;

	state = S_STOPPING;
	post stop_done();
	return SUCCESS;
}

command error_t RadioState.standby() {
	return call RadioState.turnOff();
}


command error_t RadioState.turnOn() {
	err = SUCCESS;

	if (state == S_STARTED) {
		post start_done();
		return SUCCESS;
	}

	if (call RadioPower.startVReg() != SUCCESS) return FAIL;
	state = S_STARTING;
	return SUCCESS;
}

command error_t RadioState.setChannel(uint8_t channel) {
	call RadioConfig.setChannel( channel );
	return call RadioConfig.sync();
}

command uint8_t RadioState.getChannel() {
	return call RadioConfig.getChannel();
}



/****************** RadioConfig Events ****************/
event void RadioConfig.syncDone( error_t error ) {
	signal RadioState.done();
}

task void resource_request() {
	call RadioResource.request();
}

async event void RadioPower.startVRegDone() {
	post resource_request();
}


async event void RadioPower.startOscillatorDone() {
	post finish_starting_radio();
}

event void RadioResource.granted() {
	call RadioPower.startOscillator();
}
}

