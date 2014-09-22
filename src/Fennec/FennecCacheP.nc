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

norace uint8_t current_data_seq;
nx_uint8_t var_hist[VARIABLE_HISTORY];

event void Boot.booted() {
	uint8_t i = 0;
	for ( i = 0; i < VARIABLE_HISTORY; i++) {
		var_hist[i] = UNKNOWN;
	}
	current_data_seq = 0;
}

/** 
	Fennec Data interface 
*/

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

command uint8_t FennecData.getDataSeq() {
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
	//printf("Get variable info: %d\n", var_id);
	for (i = 0; i < VARIABLE_HISTORY; i++) {
		if (global_data_info[i].var_id == var_id) {
			//printf("Found var info\n");
			return &(global_data_info[i]);
		}
	}
	//printf("NULL\n");
	return NULL;
}

void send_param_update(uint8_t var_id, process_t process_id) {
	uint8_t var_number;
	uint8_t var_offset;
	uint8_t i;

	/* application */
	var_number = processes[process_id].application_variables_number;
	var_offset = processes[process_id].application_variables_offset;

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].global_id == var_id) {
			//signal Param.updated[F_APPLICATION, process_id]
			/* nesC bug (issue #33) - reverse order */
			signal Param.updated[process_id, F_APPLICATION]
						(variable_lookup[i].var_id);
                }
        }

	/* network */
	var_number = processes[process_id].network_variables_number;
	var_offset = processes[process_id].network_variables_offset;

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].global_id == var_id) {
			//signal Param.updated[F_NETWORK, process_id]
			/* nesC bug (issue #33) - reverse order */
			signal Param.updated[process_id, F_NETWORK]
						(variable_lookup[i].var_id);
                }
        }

	/* am */
	var_number = processes[process_id].am_variables_number;
	var_offset = processes[process_id].am_variables_offset;

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].global_id == var_id) {
			//signal Param.updated[F_AM, processes[process_id].am_module]
			/* nesC bug (issue #33) - reverse order */
			signal Param.updated[processes[process_id].am_module, F_AM]
						(variable_lookup[i].var_id);
		}
	}
}

void signal_global_update(nx_uint8_t var_id) {

	struct network_process **daemons = NULL;
	struct network_process **ordinary = NULL;

	daemons = call Fennec.getDaemonProcesses();
	ordinary = call Fennec.getOrdinaryProcesses();


	while ((ordinary != NULL) && (*ordinary != NULL)) {
		//dbg("NetworkState", "[-] NetworkState call NetworkProcess.start(%d) (ordinary)\n",
                //                                (*ordinary)->process_id);
		send_param_update(var_id, (*ordinary)->process_id);
		ordinary++;
	}

	while ((daemons != NULL) && (*daemons != NULL)) {
		//dbg("NetworkState", "[-] NetworkState call NetworkProcess.start(%d) (daemons)\n",
                //                                (*daemons)->process_id);
		send_param_update(var_id, (*daemons)->process_id);
		daemons++;
	}
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
 * data      - pointer to location where the data should be copied from
 * data_len  - how much data (Bytes) can be copied to destination
 * updated_size   - pointer storing how much data (Bytes) was actually copied
 * history        - pointer to the history buffer
 * from           - starting position in the history buffer
 * to             - final position in the history buffer
 * returns        how many were history items were actually copied
 */
uint8_t sync_data_fragment(void* data, uint8_t data_len,
					uint8_t *updated_size,
					nx_uint8_t* from_history,
					nx_uint8_t from,
					nx_uint8_t to,
					bool download) {
	uint8_t *to_data_ptr = (uint8_t*) &fennec_global_data_nx;
	uint8_t *data_ptr = data;
	uint8_t i;
	uint8_t v;
	struct variable_info *v_info;
	uint8_t *mem_dest;


	*updated_size = 0;
	//printf("syncing... updated_size: %d   max_len: %d   from: %d   to: %d\n", 
	//		*updated_size, data_len, from, to);

	for(i = from; i < to && *updated_size < data_len; i++) {
		v = from_history[i];
		v_info = getVariableInfo(v);
		if (v_info == NULL) {
			break;
		}
		mem_dest = to_data_ptr + v_info->offset;

		//printf("var size: %d\n", v_info->size);

		if (download) {
			memcpy( mem_dest, data_ptr, v_info->size );
			signal_global_update(v);
		} else {
			memcpy( data_ptr, mem_dest, v_info->size );
		}
		data_ptr += v_info->size;
		*updated_size += v_info->size;

		//printf("syncing... updated_size: %d   max_len: %d   from: %d   to: %d\n", 
		//	*updated_size, data_len, from, to);
	}
	return i - from;
}

command void FennecData.updateData(void* data, uint8_t data_len, nx_uint8_t* history, uint8_t seq) {
	uint8_t i;
	uint8_t msg_hist_index;
	uint8_t var_hist_index;
	uint8_t hist_match_len;
	uint8_t updated_size;

	/* same message */
//	if ((seq == current_data_seq) && 
//		(memcmp(var_hist, history, VARIABLE_HISTORY) == 0)) {
//		/* we do not check data! if there is inconsistency, we won't catch that */
//		printf("Receive -> the same seq %d and history\n", seq);
//		return;
//	}

	/* someone lost track of the data, dump it */
	if (current_data_seq > VARIABLE_HISTORY + seq) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> got old sequence %d, signal FennecData.dump() \n", seq);
#endif
		signal FennecData.dump();
		return;
	}

	/* if we were behind, update (assume the rest of the data is synced */
	if (( current_data_seq + VARIABLE_HISTORY < seq )) {

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> we are behind; sync all\n");
#endif
		sync_data_fragment(data, data_len,
				&updated_size, history, i, VARIABLE_HISTORY, 1);
		memcpy(var_hist, history, VARIABLE_HISTORY);
		current_data_seq = seq;
		goto sync;
	}

	/* resolve update difference */
	hist_match_len = longestMatchStart(history, var_hist, &msg_hist_index, &var_hist_index);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Receive -> longestMatchStart returned hist_len %d  msg_ind %d  var_ind %d\n",
			hist_match_len, msg_hist_index, var_hist_index);
#endif

	if ( hist_match_len < VARIABLE_HISTORY / 2 ) {
		/* not much history to compare, sync all, use seq to decide */
		if (seq < current_data_seq) {
			/* received message is behind */

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Receive -> too short history (%d < %d), signal FennecData.resend(0)\n", 
				hist_match_len, VARIABLE_HISTORY / 2);
#endif
			signal FennecData.resend(0);
			return;
		}

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> too short history (%d < %d), we sink\n",
				hist_match_len, VARIABLE_HISTORY / 2);
#endif
		sync_data_fragment(data, data_len,
						&updated_size, history,
						0, VARIABLE_HISTORY, 1);
		memcpy(var_hist, history, VARIABLE_HISTORY);
		current_data_seq = seq;
		goto sync;
	}

	if (hist_match_len == VARIABLE_HISTORY) {
		/* history match, sync sequence */
		if (seq > current_data_seq) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Receive -> just update seq to %d\n", seq);
#endif
			current_data_seq = seq;
			signal FennecData.resend(0);
		}
		return;
	}

	if ( msg_hist_index == 0 && var_hist_index > 0 ) {
		/* received message is behind */
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Received message is behind\n");
#endif
		signal FennecData.resend(0);
		return;
	}

	if ( msg_hist_index > 0 ) {
		/* we are behind */
		uint8_t updated = sync_data_fragment(data, data_len, &updated_size, 
						history, 0, msg_hist_index, 1);
		if (updated != msg_hist_index) {
			/* we are missing too many data updated */
			/* someone needs to give us a dump update */
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Receive -> updated %d != %d msg_hist_index, signal FennecData.resend(1)\n",
				updated, msg_hist_index);
#endif
			current_data_seq = 0;
			signal FennecData.resend(1);
			return;
		}
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> we are synchronizing... (msg_his %d, var_his %d)\n",
				msg_hist_index, var_hist_index);
#endif
		current_data_seq += msg_hist_index;
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

//	if ( var_hist_index > 0 ) {
//		printf("Receive -> sender is also behind, signal FennecData.resend(0)\n");
//		signal FennecData.resend(0);
//	}

sync:
		
	signal FennecData.resend(0);	/* just pass it further */
	globalDataSyncWithNetwork();

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printfGlobalData();
	printfDataHistory();
	printf("Sequence: %d\n", current_data_seq);
	#endif
}


command uint8_t FennecData.fillNxDataUpdate(void *ptr, uint8_t max_size) {
	uint8_t updated_size;

	sync_data_fragment(ptr, max_size, &updated_size, 
					var_hist, 0, VARIABLE_HISTORY, 0);
	return updated_size;
}

command void FennecData.checkDataSeq(uint8_t msg_type) {
	if (LOW_DATA_ID(msg_type) != LOW_DATA_ID(current_data_seq)) {
		signal FennecData.resend(0);
	}
}


/** 
	Param interface 
*/

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

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Param.set[%u %u](%u ptr %u)\n", layer, process_id, name, size);
#endif

	if (err != SUCCESS) {
		return err;
	}

	err = FAIL;

	for (i = var_offset; i < (var_offset+var_number); i++) {
		if (variable_lookup[i].var_id == name) {
			memcpy(variable_lookup[i].ptr, value, size);
			/* update name to global id */
			name = variable_lookup[i].global_id;
			err = SUCCESS;
			break;
		}
	}

	if (err != SUCCESS) {
		return err;
	}

	if (name == UNKNOWN) {
		/* this is not a global variable */
		return SUCCESS;
	} 

	signal_global_update(name);

	for ( i = VARIABLE_HISTORY; i > 1; i-- ) {
		var_hist[i-1] = var_hist[i-2];
	}
	var_hist[0] = name;

	globalDataSyncWithLocal();
	current_data_seq++;
	signal FennecData.resend(1);

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printfGlobalData();
	printfDataHistory();
	#endif

	return SUCCESS;
}

default event void Param.updated[uint8_t layer, process_t process_id](uint8_t var_id) {
}

}

