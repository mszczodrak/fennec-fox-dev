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
#include "hashing.h"

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
uint16_t current_data_crc;

#define RANDOM_DATA_SEQ_UPDATE	10

void update_data_crc() {
	current_data_crc = crc16(0, call FennecData.getNxDataPtr(),
					call FennecData.getNxDataLen());
}

void reset_data() {
	uint8_t i = 0;
	for ( i = 0; i < VARIABLE_HISTORY; i++) {
		var_hist[i] = UNKNOWN;
	}
	current_data_seq = 0;
}

event void Boot.booted() {
	reset_data();
	update_data_crc();
	current_data_seq++;
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

command uint16_t FennecData.getDataCrc() {
	return current_data_crc;
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
uint8_t longestMatchStart(nx_uint8_t* hist1, nx_uint8_t *hist2,
				uint8_t* pus_index1, uint8_t* pus_index2) {
	uint8_t index_2;
	uint8_t index_1;
	uint8_t the_longest = 0;
	*pus_index1 = VARIABLE_HISTORY;
	*pus_index2 = VARIABLE_HISTORY;

	for ( index_1 = 0; index_1 < VARIABLE_HISTORY; index_1++ ) {
		uint8_t v1 = index_1;
		uint8_t temp_longest = 0;
		for(index_2 = 0; (index_2 < VARIABLE_HISTORY) &&
					(v1 < VARIABLE_HISTORY); index_2++ ) {
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

command void FennecData.updateData(void* in_data, uint8_t in_data_len, 
		uint16_t in_data_crc, nx_uint8_t* in_history, uint8_t in_data_seq) {
	uint8_t i;
	uint8_t in_hist_index;
	uint8_t current_hist_index;
	uint8_t hist_match_len;
	uint8_t updated_size;

	/* same message */
	//if ( in_data_crc == current_data_crc ) {
	if ( memcmp(var_hist, in_history, VARIABLE_HISTORY) == 0 ) {
		if (in_data_seq > current_data_seq) {
			current_data_seq = in_data_seq;
//			memcpy(var_hist, in_history, VARIABLE_HISTORY);
			signal FennecData.resend(0);
		}

		if (in_data_seq < current_data_seq) {
			signal FennecData.resend(0);
		}
		return;
	}

	/* requesting dump */
	if ((in_data_seq == 0) && (current_data_seq != 0)) {
		//printf("someone is requesting sending dump\n");
		signal FennecData.dump();
		return;
	}

	/* end of dump */
	if (( current_data_seq == 0 ) && (in_data_seq > 0)) {
		//printf("after dump\n");
		memcpy(var_hist, in_history, VARIABLE_HISTORY);
		current_data_seq = in_data_seq;
		update_data_crc();
		goto sync;
	}

	/* Compare two history records */
	hist_match_len = longestMatchStart(in_history, var_hist, 
					&in_hist_index, &current_hist_index);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Receive -> longestMatchStart returned hist_len %d  msg_ind %d  var_ind %d\n",
			hist_match_len, in_hist_index, current_hist_index);
#endif


	/* Can we merge ? */
	if ((hist_match_len > (VARIABLE_HISTORY / 2)) && (( in_hist_index > 0 ) || ( current_hist_index > 0 ))) {
		uint8_t updated = sync_data_fragment(in_data, in_data_len, &updated_size, 
						in_history, 0, in_hist_index, 1);

		nx_uint8_t done_max;
		uint8_t rep;
		nx_uint8_t this_max;

		update_data_crc();

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("merge: hist: %d - %d : diff hist %d : crc %u - %u\n", updated,
				in_hist_index, current_hist_index, in_data_crc, current_data_crc);
#endif

		if (( updated != in_hist_index )) { // || ( ( current_hist_index == 0 ))) && ( in_data_crc != current_data_crc ))) {
			/* we are missing too many data updates */
			/* someone needs to give us a dump update */
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("merge ERROR -> updated %d != %d in_hist_index, signal FennecData.resend(1)\n",
				updated, in_hist_index);
#endif
			goto lost;
		}

		current_data_seq += in_hist_index;
		if (in_data_seq > current_data_seq) {
			current_data_seq = in_data_seq + current_hist_index;
		}

		/* sync history */
		/* make space for msg history, while keeping the local diff in front */

		for ( i = VARIABLE_HISTORY; i > in_hist_index + current_hist_index; i-- ) {
			var_hist[i - 1] = var_hist[i - in_hist_index - current_hist_index - 1];
		}

		/* copy the message diff history */
		//for ( i = 0; i < in_hist_index; i++) {
		//	var_hist[current_hist_index + i] = in_history[i];
		//}

		done_max = 255;
		rep = in_hist_index + current_hist_index;

		while(rep > 0) {
			this_max = 0;

			/* Find the largest variable ID to be sorted */
	
			for ( i = 0; i < in_hist_index; i++  ) {
				if ((in_history[i] > this_max) && (in_history[i] < done_max)) {
					this_max = in_history[i];
				}
			}

			for ( i = 0; i < current_hist_index; i++  ) {
				if ((var_hist[i] > this_max) && (var_hist[i] < done_max)) {
					this_max = var_hist[i];
				}
			}

			/* we found max */

			for ( i = 0; i < in_hist_index; i++  ) {
				if (in_history[i] == this_max) {
					rep--;
					var_hist[rep] = this_max;
				}
			}
			for ( i = 0; i < current_hist_index; i++  ) {
				if (var_hist[i] == this_max) {
					rep--;
					var_hist[rep] = this_max;
				}
			}
			done_max = this_max;
		}

		goto sync;
	}

	if (( hist_match_len > (VARIABLE_HISTORY / 2)) && ( current_hist_index > 0 )) {
		signal FennecData.resend(0);
		return;
	}

	//printf("we cannot merge it\n");

	if ( current_data_seq > in_data_seq ) {
		#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> got old sequence %d, signal FennecData.dump() \n", in_data_seq);
		#endif
		signal FennecData.dump();
		return;
	}
	if ( current_data_seq < in_data_seq ) {
		#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("Receive -> got new sequence %d, we are lost\n", in_data_seq);
		#endif
		goto lost;
		return;
	}
	current_data_seq += (call Random.rand16() % RANDOM_DATA_SEQ_UPDATE);
	//printf("increase sequence randomly to %u\n", current_data_seq);

	signal FennecData.resend(0);
	return;

lost:
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("FennecData -> we are lost! - reset data\n");
#endif
	reset_data();
	signal FennecData.resend(1);
	return;

sync:
		
	globalDataSyncWithNetwork();

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	//printfGlobalData();
	printfDataHistory();
	printf("Sequence: %d\n", current_data_seq);
	#endif

	signal FennecData.resend(0);	/* just pass it further */
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
//	printf("Param.set[%u %u](%u ptr %u)\n", layer, process_id, name, size);
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

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("set variable %d\n", name);
#endif

	signal_global_update(name);

	for ( i = VARIABLE_HISTORY; i > 1; i-- ) {
		var_hist[i-1] = var_hist[i-2];
	}
	var_hist[0] = name;

	globalDataSyncWithLocal();
	current_data_seq++;
	update_data_crc();
	signal FennecData.resend(1);

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	//printfGlobalData();
	printfDataHistory();
	#endif

	return SUCCESS;
}

default event void Param.updated[uint8_t layer, process_t process_id](uint8_t var_id) {
}

}

