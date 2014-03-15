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
  * Fennec Fox Protocol Stack Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */

#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"

#define MODULE_RESPONSE_DELAY    200

module NetworkProcessP {
provides interface NetworkProcess;

uses interface ModuleCtrl;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
uses interface Fennec;
}

implementation {

uint8_t state = S_STOPPED;
uint8_t current_layer = UNKNOWN_LAYER;
void next_layer();
process_t current_process;

task void start_next_module() {
	uint8_t module_id = call Fennec.getModuleId(current_process, current_layer);
	error_t err = call ModuleCtrl.start(module_id);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	switch(err) {
	case EALREADY:
		signal ModuleCtrl.startDone(module_id, SUCCESS);
		return;

	case SUCCESS:
		return;

	default:
		signal NetworkProcess.startDone(FAIL);
	}
}

task void stop_next_module() {
	uint8_t module_id = call Fennec.getModuleId(current_process, current_layer);
	error_t err = call ModuleCtrl.stop(module_id);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	switch(err) {
	case EALREADY:
		signal ModuleCtrl.stopDone(module_id, SUCCESS);
		return;

	case SUCCESS:
		return;

	default:
		signal NetworkProcess.stopDone(FAIL);
	}
}

command error_t NetworkProcess.start(process_t process_id) {
	dbg("NetworkProcess", "NetworkProcessP NetworkProcess.startConf(%d)", conf);
	state = S_STARTING;
	current_layer = F_RADIO;
	current_process = process_id;
	post start_next_module();
	return 0;
}

command error_t NetworkProcess.stop(process_t process_id) {
	dbg("NetworkProcess", "NetworkProcessP NetworkProcess.stopConf(%d)", conf);
	state = S_STOPPING;
	current_layer = F_APPLICATION;
	current_process = process_id;
	post stop_next_module();
	return 0;
}

event void ModuleCtrl.startDone(uint8_t module_id, error_t error) {
	dbg("NetworkProcess", "NetworkProcess ModuleCtrl.startDone(%d, %d)", module_id, error);
	if ((error == SUCCESS) || (error = EALREADY)) {
		next_layer();
		if (current_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STARTED;
			signal NetworkProcess.startDone(SUCCESS);
		} else {
			post start_next_module();
		}
	}
}

event void ModuleCtrl.stopDone(uint8_t module_id, error_t error) {
	dbg("NetworkProcess", "NetworkProcess ModuleCtrl.stopDone(%d, %d)", module_id, error);
	if ((error == SUCCESS) || (error = EALREADY)) {
		next_layer();
		if (current_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STOPPED;
			signal NetworkProcess.stopDone(SUCCESS);
		} else {
			post stop_next_module();
		}
	}
}

event void Timer.fired() {
	if (state == S_STARTING) {
		post start_next_module();
	} else {
		post stop_next_module();
	}
}

void next_layer() {
        if (state == S_STARTING) {
                if (current_layer == F_APPLICATION) current_layer = UNKNOWN_LAYER;
                if (current_layer == F_NETWORK) current_layer = F_APPLICATION;
                if (current_layer == F_MAC) current_layer = F_NETWORK;
                if (current_layer == F_RADIO) current_layer = F_MAC;
        } else {
                if (current_layer == F_RADIO) current_layer = UNKNOWN_LAYER;
                if (current_layer == F_MAC) current_layer = F_RADIO;
                if (current_layer == F_NETWORK) current_layer = F_MAC;
                if (current_layer == F_APPLICATION) current_layer = F_NETWORK;
        }
}


}
