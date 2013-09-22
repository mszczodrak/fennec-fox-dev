#include <Fennec.h>
#include "ff_caches.h"

module CachesP @safe() {
provides interface Fennec;
provides interface SimpleStart;

uses interface SplitControl;
}

implementation {

uint16_t network_sequence = 0;
uint16_t node_sequence = 0;

uint16_t node_state = 0;

event_t event_mask;

error_t switch_to_state(state_t state_id, uint16_t seq) @C() {
}


module_t get_module_id(conf_t conf, layer_t layer) @C() {

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

state_t get_state_id() @C() {
	//return fennec_state.state;
	return active_state;
}

conf_t get_conf_id(module_t module_id) @C() {
	uint8_t i;
	conf_t conf_id;
	
	for (i = 0; i < states[get_state_id()].num_confs; i++) {
		conf_id = states[get_state_id()].conf_list[i];
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

uint16_t get_conf_id_in_state(module_t module_id) @C() {
	uint8_t i;
	conf_t conf_id;
	
	for (i = 0; i < states[get_state_id()].num_confs; i++) {
		conf_id = states[get_state_id()].conf_list[i];
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


module_t get_next_module_id(module_t from_module_id, uint8_t to_layer_it) @C() {
	return get_module_id(get_conf_id(from_module_id), to_layer_it);
}



struct stack_params get_conf_params(module_t module_id) @C() {
//	conf = get_conf_id(module_id);
        return states[get_state_id()].conf_params[get_conf_id_in_state(module_id)];
}


task void check_event() {
	uint8_t i;
	dbg("Caches", "CachesP check_event() current mask %d", event_mask);
	for( i=0; i < NUMBER_OF_POLICIES; i++ ) {
		if ((policies[i].src_conf == active_state) && (policies[i].event_mask == event_mask)) {
			call Fennec.setStateAndSeq(policies[i].dst_conf, node_sequence++);
		}
	}
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


void event_occured(module_t module_id, uint16_t oc) @C() {
	conf_t conf_id = get_conf_id(module_id);
	uint8_t event_id = get_event_id(module_id, conf_id);
	dbg("Caches", "CachesP event_occured(%d, %d)", module_id, oc);
	if (oc) {
		event_mask |= (1 << event_id);
	} else {
		event_mask -= (1 << event_id);
	}
	post check_event();
}


command void SimpleStart.start() {
	event_mask = 0;
	signal SimpleStart.startDone(SUCCESS);
	call SplitControl.start();
}

event void SplitControl.startDone(error_t err) {
	dbg("Caches", "Caches SplitControl.startDone(%d)", err);
	event_mask = 0;
}


event void SplitControl.stopDone(error_t err) {
	dbg("Caches", "Caches SplitControl.stopDone(%d)", err);
	event_mask = 0;

}

command state_t Fennec.getStateId() {
	return get_state_id();
}

command struct state* Fennec.getStateRecord() {
	return &states[get_state_id()];
}

command error_t Fennec.setStateAndSeq(state_t state_id, uint16_t seq) {
	dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d)", state_id, seq);
//	call NetworkScheduler.switch(state_t state_id);
	return SUCCESS;
}

command uint16_t Fennec.getStateSeq() {

}

}

