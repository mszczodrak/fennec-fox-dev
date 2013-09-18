#include <Fennec.h>
#include "ff_caches.h"

module CachesP @safe() {
provides interface SimpleStart;
provides interface EventCache;
provides interface PolicyCache;
}

implementation {

uint16_t network_sequence = 0;
uint16_t node_sequence = 0;

uint16_t node_state = 0;


command void SimpleStart.start() {
	signal SimpleStart.startDone(SUCCESS);
}

/*
void turnEvents(bool flag) {
	uint8_t i;
	for(i = 0 ; i < NUMBER_OF_EVENTS; i++ ) {
		if ( call EventCache.eventStatus(i)) {
			setEvent(i + 1, flag);
		}
	}
}
*/


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

module_t get_next_module_id(module_t from_module_id, uint8_t to_layer_it) @C() {
	return get_module_id(get_conf_id(from_module_id), to_layer_it);
}






struct stack_params get_conf_params(module_t module_id) @C() {
//	conf = get_conf_id(module_id);
        return states[get_state_id()].conf_params[get_conf_id(module_id)];
}


command error_t PolicyCache.set_active_configuration(state_t new_state) {
	atomic active_state = new_state;
	return SUCCESS;
}

command uint16_t PolicyCache.getNetworkSequence() {
	return network_sequence;
}

command void PolicyCache.setNetworkSequence(uint16_t seq) {
	network_sequence = seq;
}

command uint16_t PolicyCache.getNodeSequence() {
	return node_sequence;
}

command void PolicyCache.setNodeSequence(uint16_t seq) {
	node_sequence = seq;
}

command uint16_t PolicyCache.getNetworkState() {
	return active_state;
}

command void PolicyCache.setNetworkState(uint16_t state) {
	active_state = state;
}

command uint16_t PolicyCache.getNodeState() {
	return node_state;
}

command void PolicyCache.setNodeState(uint16_t state) {
	node_state = state;
}

command struct state* PolicyCache.getStateRecord(uint16_t id) {
	return &states[id];
}



command uint16_t PolicyCache.get_number_of_configurations() {
	return NUMBER_OF_CONFIGURATIONS;
}

command void PolicyCache.control_unit_support(bool status) {
}

command bool PolicyCache.valid_policy_msg(nx_struct FFControl *policy_msg) {
	if (policy_msg->conf_id >= NUMBER_OF_CONFIGURATIONS)
		return FALSE;
	return TRUE;
}

command uint8_t PolicyCache.add_accepts(nx_struct FFControl *conf) {
	return 1;
}

task void wrong_conf() {
	signal PolicyCache.wrong_conf();
}

task void check_event() {
	uint8_t i;
	for( i=0; i < NUMBER_OF_POLICIES; i++ ) {
		if (((policies[i].src_conf == ANY) || (policies[i].src_conf == active_state))
				&& (policies[i].event_mask == event_mask)) {
			signal PolicyCache.newConf( policies[i].dst_conf );
		}
	}
}


bool check_configuration(conf_t conf_id) @C() {
/*
	if ((conf_id != POLICY_CONFIGURATION) && (conf_id != active_state)) {
		signal PolicyCache.wrong_conf();
		return 1;
	}
*/
	return 0;
}



void event_occured(module_t module_id, uint16_t oc) @C() {

}



command void EventCache.clearMask() {
	event_mask = 0;
}

command void EventCache.setBit(uint16_t bit) {
	event_mask |= (1 << (bit - 1));
	post check_event();
}

command void EventCache.clearBit(uint16_t bit) {
	event_mask &= ~(1 << (bit - 1));
	post check_event();
}

command bool EventCache.eventStatus(uint16_t event_num) {
	uint8_t i;
	for( i=0; i < NUMBER_OF_POLICIES; i++ ){
		if (((policies[i].src_conf == ANY) || 
			(policies[i].src_conf == active_state)) &&
			(policies[i].event_mask & (1 << event_num))) {
			return 1;
		}
	}
	return 0;
}
}

