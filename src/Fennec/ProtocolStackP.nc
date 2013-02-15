#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"
#include "engine.h"


module ProtocolStackP {
provides interface Mgmt;

uses interface ModuleCtrl;

}

implementation {

uint8_t state = S_STOPPED;
uint8_t active_layer = UNKNOWN_LAYER;


void next_layer();
void copy_default_params(uint16_t conf_id);
uint16_t next_module();
uint8_t ctrl_conf(uint16_t conf_id);

command error_t Mgmt.start() {
	state = S_STARTING;
	return ctrl_conf(active_state);
//	return call FennecEngine.start();
}

command error_t Mgmt.stop() {
	state = S_STOPPING;
	return ctrl_conf(active_state);
//	return call FennecEngine.stop();
}

event void ModuleCtrl.startDone(uint8_t module_id, error_t error) {
        if (error != SUCCESS) {
                if (state == S_STARTING) {
                        call ModuleCtrl.start(next_module());
                } else {
                        call ModuleCtrl.stop(next_module());
                }
        } else {
                next_layer();

                if (active_layer == UNKNOWN_LAYER) {
                        if (state == S_STARTING) {
                                state = S_STARTED;
                                signal Mgmt.startDone(SUCCESS);
                        } else {
                                state = S_STOPPED;
                                signal Mgmt.stopDone(SUCCESS);
                        }
                } else {
                        if (state == S_STARTING) {
                                call ModuleCtrl.start(next_module());
                        } else {
                                call ModuleCtrl.stop(next_module());
                        }
                }
        }
}


event void ModuleCtrl.stopDone(uint8_t module_id, error_t error) {
        if (error != SUCCESS) {
                if (state == S_STARTING) {
                        call ModuleCtrl.start(next_module());
                } else {
                        call ModuleCtrl.stop(next_module());
                }
        } else {
                next_layer();

                if (active_layer == UNKNOWN_LAYER) {
                        if (state == S_STARTING) {
                                state = S_STARTED;
                                signal Mgmt.startDone(SUCCESS);
                        } else {
                                state = S_STOPPED;
                                signal Mgmt.stopDone(SUCCESS);
                        }
                } else {
                        if (state == S_STARTING) {
                                call ModuleCtrl.start(next_module());
                        } else {
                                call ModuleCtrl.stop(next_module());
                        }
                }
        }
}



uint8_t ctrl_conf(uint16_t conf_id) {
        if (state == S_STARTING) {
                copy_default_params(conf_id);
                active_layer = F_RADIO;
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
}


void copy_default_params(uint16_t conf_id) {
        //dbg("FennecEngine", "Copying Default Params\n");
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
        switch(active_layer) {
        case F_APPLICATION:
                return configurations[active_state].application;
        case F_NETWORK:
                return configurations[active_state].network;
        case F_MAC:
                return configurations[active_state].mac;
        case F_RADIO:
                return configurations[active_state].radio;
        }
        return UNKNOWN;
}

}
