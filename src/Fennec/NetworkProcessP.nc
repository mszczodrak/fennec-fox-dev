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
	module_t module_id = call Fennec.getModuleId(current_process, current_layer);
	error_t err = call ModuleCtrl.start(module_id);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	switch(err) {
	case EALREADY:
		dbg("NetworkProcess", "[-] NetworkProcess start_next_module() - EALREADY module: %d\n", module_id);
		signal ModuleCtrl.startDone(SUCCESS);
		return;

	case SUCCESS:
		dbg("NetworkProcess", "[-] NetworkProcess start_next_module() - SUCCESS module: %d\n", module_id);
		return;

	default:
		dbg("NetworkProcess", "[-] NetworkProcess start_next_module() - FAIL module: %d\n", module_id);
		signal NetworkProcess.startDone(FAIL);
	}
}

task void stop_next_module() {
	module_t module_id = call Fennec.getModuleId(current_process, current_layer);
	error_t err = call ModuleCtrl.stop(module_id);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	switch(err) {
	case EALREADY:
		dbg("NetworkProcess", "[-] NetworkProcess stop_next_module() - EALREADY module: %d\n", module_id);
		signal ModuleCtrl.stopDone(SUCCESS);
		return;

	case SUCCESS:
		dbg("NetworkProcess", "[-] NetworkProcess stop_next_module() - SUCCESS module: %d\n", module_id);
		return;

	default:
		dbg("NetworkProcess", "[-] NetworkProcess stop_next_module() - FAIL module: %d\n", module_id);
		signal NetworkProcess.stopDone(FAIL);
	}
}

command error_t NetworkProcess.start(process_t process_id) {
	dbg("NetworkProcess", "[-] NetworkProcess NetworkProcess.start(%d)\n", process_id);
	state = S_STARTING;
	current_layer = F_AM;
	current_process = process_id;
	post start_next_module();
	return 0;
}

command error_t NetworkProcess.stop(process_t process_id) {
	dbg("NetworkProcess", "[-] NetworkProcess NetworkProcess.stop(%d)\n", process_id);
	state = S_STOPPING;
	current_layer = F_APPLICATION;
	current_process = process_id;
	post stop_next_module();
	return 0;
}

event void ModuleCtrl.startDone(error_t error) {
	dbg("NetworkProcess", "[-] NetworkProcess ModuleCtrl.startDone(%d)\n", error);

	if (state != S_STARTING) {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[-] NetworkProcess in state %u got stopDone from process %u layer %u\n",
			state, current_process, current_layer);
#endif
#endif
		call Leds.led0On();
		signal NetworkProcess.stopDone(FAIL);
		return;
	}

	if ((error == SUCCESS) || (error = EALREADY)) {
		call Timer.stop();
		next_layer();
		if (current_layer == UNKNOWN_LAYER) {
			state = S_STARTED;
			dbg("NetworkProcess", "[-] NetworkProcess ModuleCtrl signal NetworkProcess.startDone(SUCCESS)\n");
			signal NetworkProcess.startDone(SUCCESS);
		} else {
			post start_next_module();
		}
	}
}

event void ModuleCtrl.stopDone(error_t error) {
	dbg("NetworkProcess", "[-] NetworkProcess ModuleCtrl.stopDone(%d)\n", error);

	if (state != S_STOPPING) {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[-] NetworkProcess in state %u got stopDone from process %u layer %u\n",
			state, current_process, current_layer);
#endif
#endif
		call Leds.led0On();
		signal NetworkProcess.startDone(FAIL);
		return;
	}

	if ((error == SUCCESS) || (error = EALREADY)) {
		call Timer.stop();
		next_layer();
		if (current_layer == UNKNOWN_LAYER) {
			state = S_STOPPED;
			dbg("NetworkProcess", "[-] NetworkProcess ModuleCtrl signal NetworkProcess.stopDone(SUCCESS)\n");
			signal NetworkProcess.stopDone(SUCCESS);
		} else {
			post stop_next_module();
		}
	}
}

event void Timer.fired() {
	if (state == S_STARTING) {
		dbg("NetworkProcess", "[-] NetworkProcess Timer.fired() - start_next_module()\n");
		post start_next_module();
	}

	if (state == S_STOPPING) {
		dbg("NetworkProcess", "[-] NetworkProcess Timer.fired() - stop_next_module()\n");
		post stop_next_module();
	}
}

void next_layer() {
        if (state == S_STARTING) {
                if (current_layer == F_APPLICATION) current_layer = UNKNOWN_LAYER;
                if (current_layer == F_NETWORK) current_layer = F_APPLICATION;
                if (current_layer == F_AM) current_layer = F_NETWORK;
        } else {
                if (current_layer == F_AM) current_layer = UNKNOWN_LAYER;
                if (current_layer == F_NETWORK) current_layer = F_AM;
                if (current_layer == F_APPLICATION) current_layer = F_NETWORK;
        }
}


}
