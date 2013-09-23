#include <Fennec.h>
#include "ff_caches.h"

module CachesP @safe() {
provides interface Fennec;
provides interface SimpleStart;
uses interface SplitControl;
}

implementation {

uint16_t active_seq = 0;
event_t event_mask;

state_t next_state = 0;
uint16_t next_seq = 0;
bool state_transitioning = TRUE;

task void check_event() {
	uint8_t i;
	dbg("Caches", "CachesP check_event() current mask %d", event_mask);
	for( i=0; i < NUMBER_OF_POLICIES; i++ ) {
		if ((policies[i].src_conf == active_state) && (policies[i].event_mask == event_mask)) {
			call Fennec.setStateAndSeq(policies[i].dst_conf, active_seq + 1);
		}
	}
}

conf_t get_conf_id(module_t module_id) {
	uint8_t i;
	conf_t conf_id;
	
	for (i = 0; i < states[call Fennec.getStateId()].num_confs; i++) {
		conf_id = states[call Fennec.getStateId()].conf_list[i];
		if ( 
			(configurations[conf_id].application == module_id)
			||
			(configurations[conf_id].network == module_id)
			||
			(configurations[conf_id].mac == module_id)
			||
			(configurations[conf_id].radio == module_id)
		) { 
			return configurations[conf_id].conf_id;
		}
	}
	return UNKNOWN_CONFIGURATION;
}

uint16_t get_conf_id_in_state(module_t module_id) {
	uint8_t i;
	conf_t conf_id;
	
	for (i = 0; i < states[call Fennec.getStateId()].num_confs; i++) {
		conf_id = states[call Fennec.getStateId()].conf_list[i];
		if ( 
			(configurations[conf_id].application == module_id)
			||
			(configurations[conf_id].network == module_id)
			||
			(configurations[conf_id].mac == module_id)
			||
			(configurations[conf_id].radio == module_id)
		) { 
			return i;
		}
	}
	return UNKNOWN_CONFIGURATION;
}

event_t get_event_id(module_t module_id, conf_t conf_id) {
	uint8_t i;
	for (i = 0; i < NUMBER_OF_EVENTS; i++) {
		if ((event_module_conf[i].module_id == module_id) &&
			(event_module_conf[i].conf_id == conf_id)) {
			return event_module_conf[i].event_id;
		}
	}
	return 0;
}

command void SimpleStart.start() {
	event_mask = 0;
	active_seq = 0;
	next_state = active_state;
	next_seq = active_seq;
	state_transitioning = TRUE;
	call SplitControl.start();
	signal SimpleStart.startDone(SUCCESS);
}

event void SplitControl.startDone(error_t err) {
	dbg("Caches", "Caches SplitControl.startDone(%d)", err);
	event_mask = 0;
	state_transitioning = FALSE;
}


event void SplitControl.stopDone(error_t err) {
	dbg("Caches", "Caches SplitControl.stopDone(%d)", err);
	event_mask = 0;
	active_state = next_state;
	active_seq = next_seq;
	call SplitControl.start();
}

/** Fennec Interface **/

async command state_t Fennec.getStateId() {
	return active_state;
}

command uint16_t Fennec.getStateSeq() {
	return active_seq;
}

command struct state* Fennec.getStateRecord() {
	return &states[call Fennec.getStateId()];
}

command error_t Fennec.setStateAndSeq(state_t state_id, uint16_t seq) {
	dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d)", state_id, seq);
	/* check if there is ongoing reconfiguration */
	if (state_transitioning) {
		dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d) - EBUSY", state_id, seq);
		return EBUSY;	
	}
	next_state = state_id;
	next_seq = seq;
	state_transitioning = TRUE;
	return call SplitControl.stop();
}

command void Fennec.eventOccured(module_t module_id, uint16_t oc) {
	conf_t conf_id = get_conf_id(module_id);
	uint8_t event_id = get_event_id(module_id, conf_id);
	dbg("Caches", "CachesP event_occured(%d, %d)", module_id, oc);
	if (oc) {
		event_mask |= (1 << event_id);
	} else {
		event_mask &= ~(1 << event_id);
	}
	post check_event();
}


async command module_t Fennec.getModuleId(conf_t conf, layer_t layer) {
	if (conf >= NUMBER_OF_CONFIGURATIONS) {
		return UNKNOWN_LAYER;
	}

	switch(layer) {

	case F_APPLICATION:
		return configurations[ conf ].application;

	case F_NETWORK:
		return configurations[ conf ].network;

	case F_MAC:
		return configurations[ conf ].mac;

	case F_RADIO:
		return configurations[ conf ].radio;

	default:
		return UNKNOWN_LAYER;
	}
}

async command conf_t Fennec.getConfId(module_t module_id) {
	uint8_t i;
	conf_t conf_id;
	
	for (i = 0; i < states[call Fennec.getStateId()].num_confs; i++) {
		conf_id = states[call Fennec.getStateId()].conf_list[i];
		if ( 
			(configurations[conf_id].application == module_id)
			||
			(configurations[conf_id].network == module_id)
			||
			(configurations[conf_id].mac == module_id)
			||
			(configurations[conf_id].radio == module_id)
		) { 
			return configurations[conf_id].conf_id;
		}
	}
	return UNKNOWN_CONFIGURATION;

}

async command module_t Fennec.getNextModuleId(module_t from_module_id, uint8_t to_layer_id) {
	return call Fennec.getModuleId(get_conf_id(from_module_id), to_layer_id);
}

async command struct stack_params Fennec.getConfParams(module_t module_id) {
        return states[call Fennec.getStateId()].conf_params[get_conf_id_in_state(module_id)];
}


}

