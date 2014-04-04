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
  * Fennec Fox Fennec
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */

#include <Fennec.h>
#include "ff_caches.h"

module FennecP @safe() {
provides interface Fennec;
provides interface FennecState;
provides interface Event;

uses interface Boot;
uses interface Leds;
uses interface SplitControl;
uses interface Random;
}

implementation {

norace uint16_t current_seq = 0;
norace state_t current_state = 0;

norace event_t event_mask;

norace state_t next_state = 0;
norace uint16_t next_seq = 0;
norace bool state_transitioning = TRUE;

task void check_event() {
	uint8_t i;
	dbg("Fennec", "[-] Fennec check_event() current mask %d", event_mask);
	for( i=0; i < NUMBER_OF_POLICIES; i++ ) {
		if ((policies[i].src_conf == current_state) && (policies[i].event_mask == event_mask)) {
			dbg("Fennec", "[-] Fennec found matching rule #%d", i);
			call FennecState.setStateAndSeq(policies[i].dst_conf, (current_seq + 1) % SEQ_MAX);
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

task void send_state_update() {
	signal FennecState.resend();
}

bool validProcessId(process_t process_id) @C() {
	struct network_process **npr;

	for(npr = daemon_processes; (*npr) != NULL ; npr++) {
		if ((*npr)->process_id == process_id) {
			return TRUE;
		}
	}

	for(npr = states[current_state].processes; (*npr) != NULL ; npr++) {
		if ((*npr)->process_id == process_id) {
			//dbg("Fennec", "[-] Fennec validProcessId(%d) - ordinary", process_id);
			return TRUE;
		}
	}

	/* we should report it */
	dbg("Fennec", "[-] Fennec validProcessId(%d) - FALSE", process_id);

	post send_state_update();	

	return FALSE;
}

event void Boot.booted() {
	event_mask = 0;
	current_seq = 0;
	current_state = active_state;
	next_state = current_state;
	next_seq = current_seq;
	state_transitioning = TRUE;
	dbg("Fennec", "[-] Fennec Boot.booted()");
	post start_state();
}

event void SplitControl.startDone(error_t err) {
	dbg("Fennec", "[-] Fennec SplitControl.startDone(%d)", err);
	event_mask = 0;
	dbg("Fennec", "[-] Fennec");
	dbg("Fennec", "[-] Fennec ");
	dbg("Fennec", "[-] Fennec ");
	post start_done();
}


event void SplitControl.stopDone(error_t err) {
	dbg("Fennec", "[-] Fennec SplitControl.stopDone(%d)", err);
	dbg("Fennec", "[-] Fennec running in state %d", current_state);
	post stop_done();
}

command void Event.report(process_t process, uint8_t status) {
	event_t event_id = UNKNOWN;
	uint8_t i;
	for (i = 0; i < NUMBER_OF_EVENTS; i++) {
		if (events[i].process_id == process) {
			dbg("Fennec", "[-] Fennec Event.report(%d, %d) found event_id %d",
				process, status, event_id);
			event_id = events[i].event_id;
			break;
		}
	}

	if (event_id == UNKNOWN) {
		dbg("Fennec", "[-] Fennec Event.report(%d, %d) event_id not found",
				process, status);
		return;
	}

	if (status) {
		dbg("Fennec", "[-] Fennec setting event id %d", event_id);
		event_mask |= (1 << event_id);
	} else {
		dbg("Fennec", "[-] Fennec clearing event id %d", event_id);
		event_mask &= ~(1 << event_id);
	}
	post check_event();
}

/** Fennec interface **/
command struct network_process** Fennec.getDaemonProcesses() {
	return daemon_processes;
}

command struct network_process** Fennec.getOrdinaryProcesses() {
	return states[current_state].processes;
}

command module_t Fennec.getModuleId(process_t process_id, layer_t layer) {
	if (process_id >= NUMBER_OF_PROCESSES) {
		return UNKNOWN_LAYER;
	}

	switch(layer) {

	case F_APPLICATION:
		return processes[ process_id ].application;

	case F_NETWORK:
		return processes[ process_id ].network;

	case F_AM:
		return processes[ process_id ].am;

	default:
		dbg("Fennec", "[-] Fennec Fennec.getModuleId(%d, %d) - UNKNOWN", process_id, layer);
		return UNKNOWN;
	}
}

/** FennecState Interface **/

command state_t FennecState.getStateId() {
	return next_state;
//	return current_state;
}

command uint16_t FennecState.getStateSeq() {
	return next_seq;
//	return current_seq;
}

/* compares received sequence with the current local one
	returns:
	0  - when sequences are equal
	1  - when the received sequence is newer
	-1 - when the current sequence is newer
*/
int8_t check_sequence(uint16_t received, uint16_t current) {
	if (received == current)
		return 0;

	/* Test overlap, where received is ahead of time */
	if ((SEQ_MAX - current < SEQ_OVERLAP) && (received < SEQ_OVERLAP))
		return 1;

	/* Test overlap, where current is ahead of time */
	if ((SEQ_MAX - received < SEQ_OVERLAP) && (current < SEQ_OVERLAP))
		return -1;

	/* A this point we do not consider overlaps anymore */
	if (received < current)
		return -1;

	if (received > current)
		return 1;

	return 1;
}

command error_t FennecState.setStateAndSeq(state_t new_state, uint16_t new_seq) {
	dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d)", new_state, new_seq);
	/* check if there is ongoing reconfiguration */
	if (state_transitioning) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - EBUSY", new_state, new_seq);
		return EBUSY;	
	}

	if (new_state >= NUMBER_OF_STATES) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - FAIL", new_state, new_seq);
		return FAIL;
	}

	/* Nothing new, receive current information */
	if ((check_sequence(new_seq, current_seq) == 0)  && (new_state == current_state)) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - nothing new", new_state, new_seq);
		return SUCCESS;
	}

	/* Some mote is still in the old state, resend control message */
	if (check_sequence(new_seq, current_seq) < 0) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - old state", new_state, new_seq);
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Network State sequnce has increased */
	if ((check_sequence(new_seq, current_seq) > 0) && (new_state == current_state)) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - update sequence", new_state, new_seq);
		current_seq = new_seq;
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Receive information about a new network state */
	if (check_sequence(new_seq, current_seq) > 0) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - new state", new_state, new_seq);
		next_state = new_state;
		next_seq = new_seq;
		state_transitioning = TRUE;
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Receive same sequence but different states - synchronize using priority levels */
	if (states[current_state].level > states[new_state].level) {
		dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - sync with level", new_state, new_seq);
		signal FennecState.resend();
		return SUCCESS;
	}
		
	/* Receive same sequence but different states with the same priority levels */ 
	dbg("Fennec", "[-] Fennec Fennec.setStateAndSeq(%d, %d) - sync with rand seq", new_state, new_seq);
	next_seq = current_seq + (call Random.rand16() % SEQ_RAND) + SEQ_OFFSET;
	state_transitioning = TRUE;
	signal FennecState.resend();
	return SUCCESS;
}

command void FennecState.resendDone(error_t error) {
	if (state_transitioning) {
		if (error == SUCCESS) {
		}
		dbg("Fennec", "[-] Fennec FennecState.resendDone(%d)", error);
		post stop_state();
	}
}

async command process_t Fennec.getProcessIdFromAM(module_t am_module_id) {
	struct network_process **npr;
	process_t process_id = UNKNOWN;
	for (npr = states[current_state].processes; (*npr) != NULL; npr++) {
		if ((*npr)->am_module == am_module_id) {
			if (!(*npr)->am_level) {
				return (*npr)->process_id;
			}
			process_id = (*npr)->process_id;
		}
	}
	return process_id;
}

default event void FennecState.resend() {}

}



