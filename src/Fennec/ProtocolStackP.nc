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
//provides interface Mgmt;
provides interface ProtocolStack;

uses interface ModuleCtrl;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint8_t state = S_STOPPED;
uint8_t active_layer = UNKNOWN_LAYER;

void next_layer();
void copy_default_params(uint16_t conf_id);
uint16_t next_module();
uint8_t ctrl_conf(uint16_t conf_id);

command error_t ProtocolStack.startConf(uint16_t conf) {
	dbg("ProtocolStack", "ProtocolStack startConf(%d)", conf);
	state = S_STARTING;
	return ctrl_conf(conf);
}

command error_t ProtocolStack.stopConf(uint16_t conf) {
	dbg("ProtocolStack", "ProtocolStack stopConf(%d)", conf);
	state = S_STOPPING;
	return ctrl_conf(conf);
}

event void ModuleCtrl.startDone(uint8_t module_id, error_t error) {
	dbg("System", "ModuleCtrl start done: %d", module_id);
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	if (error != SUCCESS) {
		call ModuleCtrl.start(next_module());
	} else {
		next_layer();

		if (active_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STARTED;
			signal ProtocolStack.startConfDone(SUCCESS);
			return;
		} else {
			call ModuleCtrl.start(next_module());
		}
	}
}


event void ModuleCtrl.stopDone(uint8_t module_id, error_t error) {
	call Timer.startOneShot(MODULE_RESPONSE_DELAY);
	if (error != SUCCESS) {
		call ModuleCtrl.stop(next_module());
	} else {
		next_layer();
		if (active_layer == UNKNOWN_LAYER) {
			call Timer.stop();
			state = S_STOPPED;
			signal ProtocolStack.stopConfDone(SUCCESS);
			return;
		} else {
			call ModuleCtrl.stop(next_module());
		}
	}
}

event void Timer.fired() {
	if (state == S_STARTING) {
		call ModuleCtrl.start(next_module());

	} else {
		call ModuleCtrl.stop(next_module());
	}
}



uint8_t ctrl_conf(uint16_t conf_id) {
	dbg("System", "Protocol Stack in ctrl_conf");
        if (state == S_STARTING) {
                copy_default_params(conf_id);
                active_layer = F_RADIO;
		dbg("System", "System: active layer is %d %d", active_layer, F_RADIO);
        } else {
                active_layer = F_APPLICATION;
        }
	if (state == S_STARTING) {
		call ModuleCtrl.start(next_module());
	} else {
		call ModuleCtrl.stop(next_module());
	}
        return 0;
}



void next_layer() {
        if (state == S_STARTING) {
                if (active_layer == F_APPLICATION) active_layer = UNKNOWN_LAYER;
                if (active_layer == F_NETWORK) active_layer = F_APPLICATION;
                if (active_layer == F_MAC) active_layer = F_NETWORK;
                if (active_layer == F_RADIO) active_layer = F_MAC;
        } else {
                if (active_layer == F_RADIO) active_layer = UNKNOWN_LAYER;
                if (active_layer == F_MAC) active_layer = F_RADIO;
                if (active_layer == F_NETWORK) active_layer = F_MAC;
                if (active_layer == F_APPLICATION) active_layer = F_NETWORK;
        }
	dbg("System", "next_layer : %d" , active_layer);
}


void copy_default_params(uint16_t conf_id) {
        dbg("FennecEngine", "Copying Default Params\n");
        memcpy( defaults[conf_id].application_cache,
                defaults[conf_id].application_default_params,
                defaults[conf_id].application_default_size);

        memcpy( defaults[conf_id].network_cache,
                defaults[conf_id].network_default_params,
                defaults[conf_id].network_default_size);

        memcpy( defaults[conf_id].mac_cache,
                defaults[conf_id].mac_default_params,
                defaults[conf_id].mac_default_size);

        memcpy( defaults[conf_id].radio_cache,
                defaults[conf_id].radio_default_params,
                defaults[conf_id].radio_default_size);
}


uint16_t next_module() {
	dbg("System", "next_module: active layer :%d", active_layer);
        switch(active_layer) {
        case F_APPLICATION:
		dbg("System", "ProtocolStack: next module is F_APPLICATION");
                return configurations[active_state].application;
        case F_NETWORK:
		dbg("System", "ProtocolStack: next module is F_NETWORK");
                return configurations[active_state].network;
        case F_MAC:
		dbg("System", "ProtocolStack: next module is F_MAC");
                return configurations[active_state].mac;
        case F_RADIO:
		dbg("System", "ProtocolStack: next module is F_RADIO");
                return configurations[active_state].radio;
        }
        return UNKNOWN;
}

}
