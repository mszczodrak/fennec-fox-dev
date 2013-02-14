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
provides interface Mgmt;
provides interface ModuleStatus as RadioStatus;
provides interface SplitControl;

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
uint8_t mgmt = FALSE;
norace error_t err;

void start_done() {
	if (err == SUCCESS) {
		state = S_STARTED;
	} else {
		state = S_STOPPED;
		call ReceiveControl.stop();
		call TransmitControl.stop();
		call RadioPower.stopVReg();
	}
	signal SplitControl.startDone(err);
	if (mgmt == TRUE) {
		signal Mgmt.startDone(err);
		mgmt = FALSE;
	}
}

task void finish_starting_radio() {
	if (call RadioPower.rxOn() != SUCCESS) err = FAIL;
	if (call RadioResource.release() != SUCCESS) err = FAIL;
	if (call ReceiveControl.start() != SUCCESS) err = FAIL;
	if (call TransmitControl.start() != SUCCESS) err = FAIL;
	start_done();
}

task void stop_done() {
	state = S_STOPPED;
	signal SplitControl.stopDone(SUCCESS);
	if (mgmt == TRUE) {
		signal Mgmt.stopDone(SUCCESS);
		mgmt = FALSE;
	}
}

command error_t Mgmt.start() {
	mgmt = TRUE;
	call SplitControl.start();
	return SUCCESS;
}

command error_t Mgmt.stop() {
	mgmt = TRUE;
	call SplitControl.stop();
	return SUCCESS;
}

command error_t SplitControl.start() {
	err = SUCCESS;
	switch(state) {

	case S_STARTED:
		start_done();
		return EALREADY;

//	case S_STARTING:
//		return SUCCESS;

	case S_STOPPED:
		state = S_STARTING;
		if (call RadioPower.startVReg() != SUCCESS) err = FAIL;
		start_done();
		return SUCCESS;
	}
	return EBUSY;
}


command error_t SplitControl.stop() {
	err = SUCCESS;
	switch(state) {

	case S_STOPPED:
		post stop_done();
		return EALREADY;

//	case S_STOPPING:
//		return SUCCESS;

	case S_STARTED:
		state = S_STOPPING;
		if (call ReceiveControl.stop() != SUCCESS) err = FAIL;
		if (call TransmitControl.stop() != SUCCESS) err = FAIL;
		if (call RadioPower.stopVReg() != SUCCESS) err = FAIL;
		post stop_done();
		return SUCCESS;
	}
	return EBUSY;
}

/*
  command error_t SplitControl.stop() {
    err = SUCCESS;
    if (state == S_STARTED) {
      state = S_STOPPING;
      if (call ReceiveControl.stop() != SUCCESS) err = FAIL;
      if (call TransmitControl.stop() != SUCCESS) err = FAIL;
      if (call RadioPower.stopVReg() != SUCCESS) err = FAIL;
      post stop_done();
      return SUCCESS;

    } else if(state == S_STOPPED) {
      post stop_done();
      return EALREADY;

    } else if(state == S_STOPPING) {
      return SUCCESS;
    }

    return EBUSY;
  }
*/

event void cc2420RadioParams.receive_status(uint16_t status_flag) {
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

