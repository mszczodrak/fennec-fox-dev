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
  * Fennec Fox Caches
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */

#include <Fennec.h>
#include "ff_caches.h"

module CachesP @safe() {
provides interface Fennec;
provides interface SimpleStart;
provides interface FennecState;
uses interface SplitControl;

uses interface Random;
}

implementation {

norace uint16_t current_seq = 0;
norace uint16_t current_state = 0;

norace event_t event_mask;

norace state_t next_state = 0;
norace uint16_t next_seq = 0;
norace bool state_transitioning = TRUE;
norace process_t systemProcessId = UNKNOWN;

task void check_event() {
	uint8_t i;
	dbg("Caches", "CachesP check_event() current mask %d", event_mask);
	for( i=0; i < NUMBER_OF_POLICIES; i++ ) {
		if ((policies[i].src_conf == call Fennec.getStateId()) && (policies[i].event_mask == event_mask)) {
			call Fennec.setStateAndSeq(policies[i].dst_conf, current_seq + 1);
			signal FennecState.resend();
			return;
		}
	}
}

task void stop_state() {
	call SplitControl.stop();
}

task void start_state() {
	call SplitControl.start();
}

task void stop_done() {
	event_mask = 0;
	current_state = next_state;
	current_seq = next_seq;
	post start_state();
}

task void start_done() {
	state_transitioning = FALSE;
}

uint16_t get_process_id_in_state(module_t module_id) {
	uint8_t i;
	process_t process_id;
	
	for (i = 0; i < states[call Fennec.getStateId()].num_processes; i++) {
		process_id = states[call Fennec.getStateId()].process_list[i];
		if ( 
			(processes[process_id].application == module_id)
			||
			(processes[process_id].network == module_id)
			||
			(processes[process_id].mac == module_id)
			||
			(processes[process_id].radio == module_id)
		) { 
			return i;
		}
	}
	return UNKNOWN_CONFIGURATION;
}

event_t get_event_id(module_t module_id, process_t process_id) {
	uint8_t i;
	for (i = 0; i < NUMBER_OF_EVENTS; i++) {
		if ((event_module_conf[i].module_id == module_id) &&
			(event_module_conf[i].process_id == process_id)) {
			return event_module_conf[i].event_id;
		}
	}
	return 0;
}

command void SimpleStart.start() {
	event_mask = 0;
	current_seq = 0;
	systemProcessId = UNKNOWN;
	current_state = active_state;
	next_state = call Fennec.getStateId();
	next_seq = call Fennec.getStateSeq();
	state_transitioning = TRUE;
	post start_state();
	signal SimpleStart.startDone(SUCCESS);
}

event void SplitControl.startDone(error_t err) {
	dbg("Caches", "CachesP SplitControl.startDone(%d)", err);
	event_mask = 0;
	dbg("Caches", " ");
	dbg("Caches", " ");
	dbg("Caches", " ");
	post start_done();
}


event void SplitControl.stopDone(error_t err) {
	dbg("Caches", "CachesP SplitControl.stopDone(%d)", err);
	dbg("Caches", "CachesP running in state %d", call Fennec.getStateId());
	post stop_done();
}

/** Fennec Interface **/

async command state_t Fennec.getStateId() {
	//dbg("Caches", "CachesP Fennec.getStateId() returns %d", current_state);
	return current_state;
}

command uint16_t Fennec.getStateSeq() {
	return current_seq;
}

command struct state* Fennec.getStateRecord() {
	return &states[call Fennec.getStateId()];
}

command error_t Fennec.setStateAndSeq(state_t new_state, uint16_t new_seq) {
	dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d)", new_state, new_seq);
	/* check if there is ongoing reconfiguration */
	if (state_transitioning) {
		dbg("Caches", "CachesP Fennec.setStateAndSeq(%d, %d) - EBUSY", new_state, new_seq);
		return EBUSY;	
	}

	if (new_seq < current_seq) {
		signal FennecState.resend();
		return SUCCESS;
	}

	if (new_seq > current_seq) {
		if (new_state == current_state) {
			current_seq = new_seq;
			signal FennecState.resend();
		} else {
			next_state = new_state;
			next_seq = new_seq;
			state_transitioning = TRUE;
			post stop_state();
		}
		return SUCCESS;
	}

	if ((new_state != current_state) && (new_seq == current_seq)) {
		current_seq += (call Random.rand16() % SEQ_RAND) + SEQ_OFFSET;
		signal FennecState.resend();
	}

	return SUCCESS;
}

command void Fennec.eventOccured(module_t module_id, uint16_t oc) {
	process_t process_id = call Fennec.getConfId(module_id);
	uint8_t event_id = get_event_id(module_id, process_id);
	dbg("Caches", "CachesP Fennec.eventOccured(%d, %d)", module_id, oc);
	if (oc) {
		event_mask |= (1 << event_id);
	} else {
		event_mask &= ~(1 << event_id);
	}
	post check_event();
}


async command module_t Fennec.getModuleId(process_t conf, layer_t layer) {
	if (conf >= NUMBER_OF_PROCESSES) {
		return UNKNOWN_LAYER;
	}

	switch(layer) {

	case F_APPLICATION:
		return processes[ conf ].application;

	case F_NETWORK:
		return processes[ conf ].network;

	case F_MAC:
		return processes[ conf ].mac;

	case F_RADIO:
		return processes[ conf ].radio;

	default:
		return UNKNOWN_LAYER;
	}
}

async command process_t Fennec.getConfId(module_t module_id) {
	uint8_t i;
	process_t process_id;

	for (i = 0; i < states[call Fennec.getStateId()].num_processes; i++) {
		process_id = states[call Fennec.getStateId()].process_list[i];
		if ( 
			(processes[process_id].application == module_id)
			||
			(processes[process_id].network == module_id)
			||
			(processes[process_id].mac == module_id)
			||
			(processes[process_id].radio == module_id)
		) { 
			//dbg("Caches", "Fennec.getConfId(%d) returns %d",
			//	module_id, processes[process_id].process_id);
			return processes[process_id].process_id;
		}
	}
	dbg("Caches", "Current state is %d", call Fennec.getStateId());
	dbg("Caches", "Fennec.getConfId(%d) returns %d",
			module_id, UNKNOWN_CONFIGURATION);
	return UNKNOWN_CONFIGURATION;

}

async command module_t Fennec.getNextModuleId(module_t from_module_id, uint8_t to_layer_id) {
//	process_t c = call Fennec.getConfId(from_module_id);
	return call Fennec.getModuleId(call Fennec.getConfId(from_module_id), to_layer_id);
}

command void Fennec.systemProcessId(process_t process_id) {
	systemProcessId = process_id;
}

default async event void FennecState.resend() {}

bool validProcessId(uint8_t process_id) @C() {
	struct state *this_state = &states[call Fennec.getStateId()];
	uint8_t i;

	if (process_id == systemProcessId) {
		return SUCCESS;
	}

	for(i = 0; i < this_state->num_processes; i++) {
		if (this_state->process_list[i] == process_id) {
			//printf("success %d %d\n", this_state->process_list[i], process_id);
			return TRUE;
		}
	}
	/* we should report it */
	signal FennecState.resend();
	
	return FALSE;
}

}



