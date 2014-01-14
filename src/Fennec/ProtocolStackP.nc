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
  * Fennec Fox Protocol Stack Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */

#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"

#define MODULE_RESPONSE_DELAY    200

module ProtocolStackP {
provides interface ProtocolStack;

uses interface ModuleCtrl;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
uses interface Fennec;
}

implementation {

uint8_t state = S_STOPPED;
uint8_t current_layer = UNKNOWN_LAYER;
void next_layer();
uint16_t current_conf;

task void start_conf_done() {
	signal ProtocolStack.startConfDone(SUCCESS);
}

task void stop_conf_done() {
	signal ProtocolStack.stopConfDone(SUCCESS);
}

task void start_next_module() {
	call ModuleCtrl.start(call Fennec.getModuleId(current_conf, current_layer));
}

task void stop_next_module() {
	call ModuleCtrl.stop(call Fennec.getModuleId(current_conf, current_layer));
}


command error_t ProtocolStack.startConf(uint16_t conf) {
	dbg("ProtocolStack", "ProtocolStackP ProtocolStack.startConf(%d)", conf);
	state = S_STARTING;
	current_layer = F_RADIO;
	current_conf = conf;
	call ModuleCtrl.start(call Fennec.getModuleId(current_conf, current_layer));
	return 0;
}

command error_t ProtocolStack.stopConf(uint16_t conf) {
	dbg("ProtocolStack", "ProtocolStackP ProtocolStack.stopConf(%d)", conf);
	state = S_STOPPING;
	current_layer = F_APPLICATION;
	current_conf = conf;
	call ModuleCtrl.stop(call Fennec.getModuleId(current_conf, current_layer));
	return 0;
}

event void ModuleCtrl.startDone(uint8_t module_id, error_t error) {
	dbg("ProtocolStack", "ProtocolStack ModuleCtrl.startDone(%d, %d)", module_id, error);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	if (error != SUCCESS) {
		call ModuleCtrl.start(module_id);
	} else {
		next_layer();

		if (current_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STARTED;
			post start_conf_done();
			return;
		} else {
			post start_next_module();
		}
	}
}


event void ModuleCtrl.stopDone(uint8_t module_id, error_t error) {
	dbg("ProtocolStack", "ProtocolStack ModuleCtrl.stopDone(%d, %d)", module_id, error);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	if (error != SUCCESS) {
		call ModuleCtrl.stop(module_id);
	} else {
		next_layer();
		if (current_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STOPPED;
			post stop_conf_done();
			return;
		} else {
			post stop_next_module();
		}
	}
}

event void Timer.fired() {
	if (state == S_STARTING) {
		call ModuleCtrl.start(call Fennec.getModuleId(current_conf, current_layer));

	} else {
		call ModuleCtrl.stop(call Fennec.getModuleId(current_conf, current_layer));
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
