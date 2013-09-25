/*
 *  Fennec Fox platform.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * author:      Marcin Szczodrak
 * date:        10/02/2009
 * last update: 02/14/2013
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
