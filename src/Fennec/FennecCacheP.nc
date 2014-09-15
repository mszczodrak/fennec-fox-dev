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

module FennecCacheP @safe() {
provides interface FennecData;
provides interface Param[process_t process, uint8_t layer];

uses interface Boot;
uses interface Random;
uses interface Fennec;
}

implementation {

norace uint16_t current_data_seq = 0;
nx_uint8_t var_hist[VARIABLE_HISTORY];

event void Boot.booted() {
	uint8_t i = 0;
	for ( i = 0; i < VARIABLE_HISTORY; i++) {
		var_hist[i] = UNKNOWN;
	}
	current_data_seq = 0;
}

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

command void* FennecData.getHistory() {
	return var_hist;
}

struct variable_info * getVariableInfo(uint8_t var_id) {
	uint8_t i;
	printf("Get variable info: %d\n", var_id);
	for (i = 0; i < VARIABLE_HISTORY; i++) {
		if (global_data_info[i].var_id == var_id) {
			printf("Found var info\n");
			return &(global_data_info[i]);
		}
	}
	printf("NULL\n");
	return NULL;
}

/* returns the position in the received history from where
 * the history matches with the local status
 */
uint8_t longestMatchStart(nx_uint8_t* hist1, nx_uint8_t *hist2, uint8_t* pus_index1, uint8_t* pus_index2) {
	uint8_t index_2;
	uint8_t index_1;
	uint8_t the_longest = 0;
	*pus_index1 = VARIABLE_HISTORY;
	*pus_index2 = VARIABLE_HISTORY;

	for ( index_1 = 0; index_1 < VARIABLE_HISTORY; index_1++ ) {
		uint8_t v1 = index_1;
		uint8_t temp_longest = 0;
		for(index_2 = 0; index_2 < VARIABLE_HISTORY && v1 < VARIABLE_HISTORY; index_2++ ) {
			if (hist1[v1] == hist2[index_2]) {
				temp_longest++;
				v1++;
			} else {
				temp_longest = 0;
			}
		}
		if (temp_longest > the_longest) {
			the_longest = temp_longest;
			*pus_index1 = index_1;
			*pus_index2 = index_2 - the_longest; 
		}
	}
	return the_longest;
}

/* 
 * syncs data with local cache, 
 * to_data        - pointer to the destination where the data should be copied to
 * from_data      - pointer to location where the data should be copied from
 * from_data_len  - how much data (Bytes) can be copied to destination
 * updated_size   - pointer storing how much data (Bytes) was actually copied
 * history        - pointer to the history buffer
 * from           - starting position in the history buffer
 * to             - final position in the history buffer
 * returns        how many were history items were actually copied
 */
uint8_t sync_data_fragment(void* to_data, void* from_data, uint8_t from_data_len,
					uint8_t *updated_size,
					nx_uint8_t* from_history,
					nx_uint8_t from,
					nx_uint8_t to) {
	uint8_t *to_data_ptr = (uint8_t*) to_data;
	uint8_t *from_data_ptr = from_data;
	uint8_t i;
	uint8_t v;
	struct variable_info *v_info;
	uint8_t *mem_dest;


	*updated_size = 0;
	printf("syncing... updated_size: %d   max_len: %d   from: %d   to: %d\n", 
			*updated_size, from_data_len, from, to);

	for(i = from; i < to && *updated_size < from_data_len; i++) {
		v = from_history[i];
		v_info = getVariableInfo(v);
		if (v_info == NULL) {
			break;
		}
		mem_dest = to_data_ptr + v_info->offset;

		printf("var size: %d\n", v_info->size);

		memcpy( mem_dest, from_data_ptr, v_info->size );
		from_data_ptr += v_info->size;
		*updated_size += v_info->size;

		printf("syncing... updated_size: %d   max_len: %d   from: %d   to: %d\n", 
			*updated_size, from_data_len, from, to);
	}
	return i - from;
}

command void FennecData.updateData(void* data, uint8_t data_len, nx_uint8_t* history, uint16_t seq) {
	uint8_t i;
	uint8_t msg_hist_index;
	uint8_t var_hist_index;
	uint8_t hist_match_len;
	uint8_t updated_size;

	/* same message */
	if ((seq == current_data_seq) && 
		(memcmp(var_hist, history, VARIABLE_HISTORY) == 0)) {
		printf("the same seq %d and history\n", seq);
		return;
	}

	/* someone lost track of the data, dump it */
	if (current_data_seq > VARIABLE_HISTORY + seq) {
		printf("got old sequence %d, dump our data\n", seq);
		signal FennecData.dump();
		return;
	}

	/* if we were behind, update (assume the rest of the data is synced */
	if (( current_data_seq + VARIABLE_HISTORY < seq )) {
		printf("sync all\n");
		sync_data_fragment(&fennec_global_data_nx, data, data_len,
				&updated_size, history, i, VARIABLE_HISTORY);
		memcpy(var_hist, history, VARIABLE_HISTORY);
		current_data_seq = seq;
		goto sync;
	}

	/* resolve update difference */
	hist_match_len = longestMatchStart(history, var_hist, &msg_hist_index, &var_hist_index);
	printf("longestMatchStart returned hist_len %d  msg_ind %d  var_ind %d\n",
			hist_match_len, msg_hist_index, var_hist_index);

	if ( hist_match_len < VARIABLE_HISTORY / 2 ) {
		/* not much history to compare, sync all, use seq to decide */
		if (seq < current_data_seq) {
			/* received message is behind */
			printf("short history (%d < %d), we resend\n", 
				hist_match_len, VARIABLE_HISTORY / 2);
			signal FennecData.resend(0);
			return;
		}

		printf("short history (%d < %d), we sink\n",
				hist_match_len, VARIABLE_HISTORY / 2);
		sync_data_fragment(&fennec_global_data_nx, data, data_len,
						&updated_size, history,
						0, VARIABLE_HISTORY);
		memcpy(var_hist, history, VARIABLE_HISTORY);
		current_data_seq = seq;
		goto sync;
	}

	if ( msg_hist_index == var_hist_index ) {
		/* history match, sync sequence */
		if (seq > current_data_seq) {
			printf("just update seq\n");
			current_data_seq = seq;
		}
		goto sync;
	}

	if ( msg_hist_index == 0 && var_hist_index > 0 ) {
		/* received message is behind */
		printf("received is behind, we resend\n");
		signal FennecData.resend(0);
		return;
	}

	if ( msg_hist_index > 0 ) {
		/* we are behind */
		uint8_t updated = sync_data_fragment(&fennec_global_data_nx,
						data, data_len, &updated_size, 
						history, 0, msg_hist_index);
		if (updated != msg_hist_index) {
			/* we are missing too many data updated */
			/* someone needs to give us a dump update */
			printf("updated %d != %d msg_hist_index, we need to get dump\n",
				updated, msg_hist_index);
			current_data_seq = 0;
			signal FennecData.resend(1);
			return;
		}
		printf("we are synchronizing... (msg_his %d, var_his %d)\n",
				msg_hist_index, var_hist_index);
		current_data_seq += seq;
		if (seq > current_data_seq) {
			current_data_seq = seq + var_hist_index;
		}
	}

	/* sync history */
	/* make space for msg history, while keeping the local diff in front */

	for ( i = VARIABLE_HISTORY; i - msg_hist_index > var_hist_index; i-- ) {
		var_hist[i-1] = var_hist[i-msg_hist_index-1];
	}

	/* copy the message diff history */
	for ( i = 0; i < msg_hist_index; i++) {
		var_hist[var_hist_index + i] = history[i];
	} 

sync:
	globalDataSyncWithNetwork();

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("FennecData.setDataAndSeq - UPDATE FROM NETWORK\n");
	printfGlobalData();
	printfDataHistory();
	#endif
}


command uint8_t FennecData.fillNxDataUpdate(void *ptr, uint8_t max_size) {
	uint8_t updated_size;
	sync_data_fragment(ptr, &fennec_global_data_nx, max_size, &updated_size, 
					var_hist, 0, VARIABLE_HISTORY);
	return updated_size;
}


/** Param interface */

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

	for ( i = VARIABLE_HISTORY; i > 1; i-- ) {
		var_hist[i-1] = var_hist[i-2];
	}
	var_hist[0] = name;

	globalDataSyncWithLocal();
	current_data_seq++;
	signal FennecData.resend(1);

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Application sets variable %u\n", name);
	printfGlobalData();
	printfDataHistory();
	#endif

	return SUCCESS;
}


}

