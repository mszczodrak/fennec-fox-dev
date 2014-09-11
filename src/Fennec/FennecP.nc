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
provides interface FennecData;
provides interface Event;
provides interface Param[process_t process, uint8_t layer];

uses interface Boot;
uses interface Leds;
uses interface SplitControl;
uses interface Random;

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

norace uint16_t current_data_seq = 0;

nx_uint8_t var_hist[VARIABLE_HISTORY];

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
	call SerialDbgs.dbgs(DBGS_STOP, 0, current_state, current_seq);
#endif
	call SplitControl.stop();
}

task void start_state() {
#ifdef __DBGS__FENNEC__
	call SerialDbgs.dbgs(DBGS_START, 0, current_state, current_seq);
#endif
	call SplitControl.start();
}

task void stop_done() {
#ifdef __DBGS__FENNEC__
	call SerialDbgs.dbgs(DBGS_STOP_DONE, 0, current_state, current_seq);
#endif
	event_mask = 0;
	current_state = next_state;
	current_seq = next_seq;
	//printf("Fennec Reconfiguration        v %d                -> %d\n", next_seq, next_state);
	post start_state();
}

task void start_done() {
#ifdef __DBGS__FENNEC__
	call SerialDbgs.dbgs(DBGS_START_DONE, 0, current_state, current_seq);
#endif
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
			return TRUE;
		}
	}

	/* we should report it */
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
		event_mask |= (1 << event_id);
	} else {
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
		current_seq = new_seq;
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

/** Fennec Data interface */

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
void printfDataHistory() {
	uint8_t i;
	printf("Var hist: ");
	for(i = 0; i < VARIABLE_HISTORY; i++) {
		printf(" %u ", var_hist[i]);
	}
	printf("\n");
}
#endif


command uint16_t FennecData.getDataSeq() {
	return current_data_seq;
}

command uint16_t FennecData.getNxDataLen() {
	return sizeof(nx_struct global_data_msg);
}

command void* FennecData.getNxDataPtr() {
	return &fennec_global_data_nx;
}

command error_t FennecData.fillDataHist(void *history, uint8_t len) {
	memcpy(history, &var_hist, len);
	return SUCCESS;
}

command uint8_t FennecData.fillNxDataUpdate(void *ptr, uint8_t max_size) {
	//memcpy(ptr, &fennec_global_data_nx, sizeof(nx_struct global_data_msg));
	return 0;
}

command error_t FennecData.setDataHistSeq(nx_struct global_data_msg* data, nx_uint8_t* history, uint16_t seq) {
	uint16_t diff;

	/* we lost track of the data, sync all */
	if (seq + VARIABLE_HISTORY >= current_data_seq) {
		current_data_seq = seq;
		memcpy(&fennec_global_data_nx, data, sizeof(nx_struct global_data_msg));
		memcpy(var_hist, history, VARIABLE_HISTORY);
		goto sync;
	}

	/* same message */
	if ((seq == current_data_seq) && 
		(memcmp(var_hist, history, VARIABLE_HISTORY) == 0)) {
		//(memcmp(&fennec_global_data_nx, data, sizeof(nx_struct global_data_msg)) == 0)) {
		//counter++;
		return SUCCESS;
	}



	/* someone is behind */
	if (seq < current_data_seq) {
		signal FennecData.resend();
		return SUCCESS;
	}


	current_data_seq = seq;
	memcpy(&fennec_global_data_nx, data, sizeof(nx_struct global_data_msg));
	memcpy(var_hist, history, VARIABLE_HISTORY);


sync:
	globalDataSyncWithNetwork();

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("FennecData.setDataAndSeq - UPDATE FROM NETWORK\n");
	printfGlobalData();
	printfDataHistory();
	#endif

	return SUCCESS;
}

command void FennecData.syncNetwork() {
	globalDataSyncWithLocal();
	current_data_seq++;
	signal FennecData.resend();
}

/** Fennec interface */

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

	for (npr = daemon_processes; (*npr) != NULL; npr++) {
		if ((*npr)->am_module == am_module_id) {
			if (!(*npr)->am_level) {
				return (*npr)->process_id;
			}
			process_id = (*npr)->process_id;
		}
	}

	return process_id;
}


error_t layer_variables(process_t process_id, uint8_t layer, uint8_t *num, uint8_t *off) {

	if (layer == F_APPLICATION) {
		*num = processes[process_id].application_variables_number;
		*off = processes[process_id].application_variables_offset;
		return SUCCESS;
	}

	if (layer == F_NETWORK) {
		*num = processes[process_id].network_variables_number;
		*off = processes[process_id].network_variables_offset;
		return SUCCESS;
	}

	/* find for which process radio is dominant */
	//printf("checking for radio layer module %d\n", process_id);
	if (layer == F_AM) {
		process_id = call Fennec.getProcessIdFromAM(process_id);
		//printf("new process id is %d\n", process_id);
		*num = processes[process_id].am_variables_number;
		*off = processes[process_id].am_variables_offset;
		return SUCCESS;
	}

	*num = UNKNOWN;
	*off = UNKNOWN;

	return F_ENOLAYER;
}

command error_t Param.get[uint8_t layer, process_t process_id](uint8_t name, void *value, uint8_t size) {
	uint8_t var_number;
	uint8_t var_offset;
	uint8_t i;
	error_t err = layer_variables(process_id, layer, &var_number, &var_offset);

	//printf("param get l:%d p:%d  n:%d   vnum:%d    voff:%d\n", layer, process_id, name, var_number, var_offset);
	//printfflush();

	if (err != SUCCESS) {
		return err;
	}

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].var_id == name) {
			memcpy(value, variable_lookup[i].ptr, size);
			return SUCCESS;
		}
	}

        return FAIL;
}

command error_t Param.set[uint8_t layer, process_t process_id](uint8_t name, void *value, uint8_t size) {
	uint8_t var_number;
	uint8_t var_offset;
	uint8_t i;
	error_t err = layer_variables(process_id, layer, &var_number, &var_offset);

	printf("Param.set[%u %u](%u ptr %u)\n", layer, process_id, name, size);

	if (err != SUCCESS) {
		return err;
	}

	err = FAIL;

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].var_id == name) {
			memcpy(variable_lookup[i].ptr, value, size);
			err = SUCCESS;
			break;
		}
	}

	if (err != SUCCESS) {
		return err;
	}

	for(i = VARIABLE_HISTORY; i > 1; i--) {
		var_hist[i-1] = var_hist[i-2];
	}
	var_hist[0] = name;

	call FennecData.syncNetwork();

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Application sets variable %u\n", name);
	printfGlobalData();
	printfDataHistory();
	#endif

	return SUCCESS;
}


}

