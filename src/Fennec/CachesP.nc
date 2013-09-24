#include <Fennec.h>
#include "ff_caches.h"

module CachesP @safe() {
provides interface Fennec;
provides interface SimpleStart;
provides interface FennecWarnings;
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
		if ((policies[i].src_conf == call Fennec.getStateId()) && (policies[i].event_mask == event_mask)) {
			call Fennec.setStateAndSeq(policies[i].dst_conf, active_seq + 1);
		}
	}
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
	next_state = call Fennec.getStateId();
	next_seq = call Fennec.getStateSeq();
	state_transitioning = TRUE;
	call SplitControl.start();
	signal SimpleStart.startDone(SUCCESS);
}

event void SplitControl.startDone(error_t err) {
	dbg("Caches", "CachesP SplitControl.startDone(%d)", err);
	event_mask = 0;
	state_transitioning = FALSE;
	call Fennec.getStateId();
	dbg("Caches", " ");
	dbg("Caches", " ");
	dbg("Caches", " ");
}


state_t get_state_id() @C() {
	dbg("Caches", "CachesP get_state_id() returns %d", active_state);
	return active_state;
}

event void SplitControl.stopDone(error_t err) {
	dbg("Caches", "CachesP SplitControl.stopDone(%d)", err);
	atomic {
		event_mask = 0;
		active_state = next_state;
		active_seq = next_seq;
	dbg("Caches", "CachesP SplitControl.stopDone(%d) - active state becomes %d", err, active_state);
	}
	dbg("Caches", " ");
	dbg("Caches", " ");
	dbg("Caches", " ");
	call SplitControl.start();
}

/** Fennec Interface **/

async command state_t Fennec.getStateId() {
	dbg("Caches", "CachesP Fennec.getStateId() returns %d", active_state);
	return active_state;
}

command uint16_t Fennec.getStateSeq() {
	return active_seq;
}

command struct state* Fennec.getStateRecord() {
	return &states[call Fennec.getStateId()];
}

command error_t Fennec.setStateAndSeq(state_t state_id, uint16_t seq) {
	dbg("Caches", " ");
	dbg("Caches", " ");
	dbg("Caches", " ");
	dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d)", state_id, seq);
	/* check if there is ongoing reconfiguration */
	if (state_transitioning) {
		dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d) - EBUSY", state_id, seq);
		return EBUSY;	
	}
	/* check if this is only sequence change */
	if (state_id == call Fennec.getStateId()) {
		active_seq = seq;
		return SUCCESS;
	}
	next_state = state_id;
	next_seq = seq;
	state_transitioning = TRUE;
	return call SplitControl.stop();
}

command void Fennec.eventOccured(module_t module_id, uint16_t oc) {
	conf_t conf_id = call Fennec.getConfId(module_id);
	uint8_t event_id = get_event_id(module_id, conf_id);
	dbg("Caches", "CachesP Fennec.eventOccured(%d, %d)", module_id, oc);
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
			//dbg("Caches", "Fennec.getConfId(%d) returns %d",
			//	module_id, configurations[conf_id].conf_id);
			return configurations[conf_id].conf_id;
		}
	}
	dbg("Caches", "Fennec.getConfId(%d) returns %d",
			module_id, UNKNOWN_CONFIGURATION);
	return UNKNOWN_CONFIGURATION;

}

async command module_t Fennec.getNextModuleId(module_t from_module_id, uint8_t to_layer_id) {
//	conf_t c = call Fennec.getConfId(from_module_id);
	return call Fennec.getModuleId(call Fennec.getConfId(from_module_id), to_layer_id);
}

async command struct stack_params Fennec.getConfParams(module_t module_id) {
        return states[call Fennec.getStateId()].conf_params[get_conf_id_in_state(module_id)];
}

async command error_t Fennec.checkPacket(message_t *msg, uint8_t len) {
	if (msg->conf >= NUMBER_OF_CONFIGURATIONS) {
		dbg("Caches", "CachesP Fennec.checPacket(0x%1x, %d) - FAIL", msg, len);
		signal FennecWarnings.detectWrongConfiguration();
		return FAIL;
	} 
	return SUCCESS;
}

default async event void FennecWarnings.detectWrongConfiguration() {}


}

