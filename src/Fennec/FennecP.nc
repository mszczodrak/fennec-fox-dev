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
#include "SerialDbgs.h"

module FennecP @safe() {
provides interface Fennec;
provides interface FennecState;
provides interface Event;

uses interface Boot;
uses interface Leds;
uses interface SplitControl;
uses interface Random;
uses interface FennecData;

uses interface SerialDbgs;
}

implementation {

norace uint16_t current_seq = 0;
norace state_t current_state = 0;
norace uint8_t rules_counter = NUMBER_OF_POLICIES;
norace event_t event_mask;
norace state_t next_state = 0;
norace uint16_t next_seq = 0;
norace bool state_transitioning = TRUE;

task void check_event() {
	uint8_t i;
	for( i=0; i < rules_counter; i++ ) {
		if ((policies[i].src_conf == current_state) && (policies[i].event_mask == event_mask)) {
			call FennecState.setStateAndSeq(policies[i].dst_conf, (current_seq + 1) % SEQ_MAX);
			return;
		}
	}
}

task void stop_state() {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[-] FennecP Stop State: %u Sequence: %u\n", current_state, current_seq);
#else
	call SerialDbgs.dbgs(DBGS_STOP, 0, current_state, current_seq);
#endif
#endif
	call SplitControl.stop();
}

task void start_state() {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[-] FennecP Start State: %u Sequence: %u\n", current_state, current_seq);
#else
	call SerialDbgs.dbgs(DBGS_START, 0, current_state, current_seq);
#endif
#endif
	call SplitControl.start();
}

task void stop_done() {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[-] FennecP StopDone State: %u Sequence: %u\n", current_state, current_seq);
#else
	call SerialDbgs.dbgs(DBGS_STOP_DONE, 0, current_state, current_seq);
#endif
#endif
	event_mask = 0;
	current_state = next_state;
	current_seq = next_seq;
	post start_state();
}

task void start_done() {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[-] FennecP StartDone State: %u Sequence: %u\n", current_state, current_seq);
#else
	call SerialDbgs.dbgs(DBGS_START_DONE, 0, current_state, current_seq);
#endif
#endif
	state_transitioning = FALSE;
}

task void send_state_update() {
	signal FennecState.resend();
}

event void Boot.booted() {
	event_mask = 0;
	current_seq = 0;
	current_state = active_state;
	next_state = current_state;
	next_seq = current_seq;
	state_transitioning = TRUE;
	post start_state();
}

event void SplitControl.startDone(error_t err) {
	event_mask = 0;
	post start_done();
}


event void SplitControl.stopDone(error_t err) {
	post stop_done();
}

command void Event.report(process_t process, uint8_t status) {
	event_t event_id = UNKNOWN;
	uint8_t i;
	for (i = 0; i < NUMBER_OF_EVENTS; i++) {
		if (events[i].process_id == process) {
			event_id = events[i].event_id;
			break;
		}
	}

	if (event_id == UNKNOWN) {
		return;
	}

	if (status) {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[-] FennecP Event %u ON\n", event_id);
#endif
#endif
		event_mask |= (1 << event_id);
	} else {
#ifdef __DBGS__FENNEC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[-] FennecP Event %u OFF\n", event_id);
#endif
#endif
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
		return UNKNOWN;
	}
}

async command process_t Fennec.getProcessIdFromAM(module_t am_module_id) {
	struct network_process **npr;
	process_t process_id = UNKNOWN;

	for (npr = states[current_state].processes; (*npr) != NULL; npr++) {
		if ((*npr)->am_module == am_module_id) {
			if ((*npr)->am_dominant) {
				return (*npr)->process_id;
			}
			process_id = (*npr)->process_id;
		}
	}

	if (process_id != UNKNOWN) {
		return process_id;
	}

	for (npr = daemon_processes; (*npr) != NULL; npr++) {
		if ((*npr)->am_module == am_module_id) {
			if ((*npr)->am_dominant) {
				return (*npr)->process_id;
			}
			process_id = (*npr)->process_id;
		}
	}

	return process_id;
}




/** FennecState Interface **/

command state_t FennecState.getStateId() {
	return next_state;
}

command uint16_t FennecState.getStateSeq() {
	return next_seq;
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
	/* check if there is ongoing reconfiguration */
	if (state_transitioning) {
		return EBUSY;	
	}

	if (new_state >= NUMBER_OF_STATES) {
		return FAIL;
	}

	/* Nothing new, receive current information */
	if ((check_sequence(new_seq, current_seq) == 0)  && (new_state == current_state)) {
		return SUCCESS;
	}

	/* Some mote is still in the old state, resend control message */
	if (check_sequence(new_seq, current_seq) < 0) {
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Network State sequnce has increased */
	if ((check_sequence(new_seq, current_seq) > 0) && (new_state == current_state)) {
		next_seq = new_seq;
		current_seq = next_seq;
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Receive information about a new network state */
	if (check_sequence(new_seq, current_seq) > 0) {
		next_state = new_state;
		next_seq = new_seq;
		state_transitioning = TRUE;
		signal FennecState.resend();
		return SUCCESS;
	}

	/* Receive same sequence but different states - synchronize using priority levels */
	if (states[current_state].level > states[new_state].level) {
		signal FennecState.resend();
		return SUCCESS;
	}
		
	/* Receive same sequence but different states with the same priority levels */ 
	next_seq = current_seq + (call Random.rand16() % SEQ_RAND) + SEQ_OFFSET;
	state_transitioning = TRUE;
	signal FennecState.resend();
	return SUCCESS;
}

command void FennecState.resendDone(error_t error) {
	if (state_transitioning) {
		if (error == SUCCESS) {
		}
		post stop_state();
	}
}

default event void FennecState.resend() {}

/** 
	Global C-like functions - part of ff_functions 
*/

bool validProcessId(nx_uint8_t msg_type) @C() {
	struct network_process **npr;

	for(npr = daemon_processes; (*npr) != NULL ; npr++) {
		if (((*npr)->process_id) == LOW_PROC_ID(msg_type)) {
			return TRUE;
		}
	}

	for(npr = states[current_state].processes; (*npr) != NULL ; npr++) {
		if (((*npr)->process_id) == LOW_PROC_ID(msg_type)) {
			return TRUE;
		}
	}

	/* we should report it */
	post send_state_update();	
	return FALSE;
}

nx_uint8_t setFennecType(nx_uint8_t id) @C() {
	nx_uint8_t newType;
	newType = id << 4;
	//newType += LOW_DATA_ID(call FennecData.getDataSeq());
	newType += LOW_DATA_ID(call FennecData.getDataCrc());
	return newType;
}

event void FennecData.updated() {}
event void FennecData.resend() {}

}
