/*
 *  cc2420 radio module for Fennec Fox platform.
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
 * Network: cc2420 Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
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

}

command uint8_t RadioState.getChannel() {

}



/****************** RadioConfig Events ****************/
event void RadioConfig.syncDone( error_t error ) {
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

