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

#define RANDOM_DATA_SEQ_UPDATE	10
uint16_t current_data_crc;

void update_data_crc() {
	current_data_crc = crc16(0, call FennecData.getNxDataPtr(),
					call FennecData.getNxDataLen());
}

event void Boot.booted() {
	update_data_crc();
}

command uint16_t FennecData.getNxDataLen() {
	return sizeof(nx_struct global_data_msg);
}

command void* FennecData.getNxDataPtr() {
	return &fennec_global_data_nx;
}

command uint16_t FennecData.getDataCrc() {
	return current_data_crc;
}

command uint8_t FennecData.getNumOfGlobals() {
	return NUMBER_OF_GLOBALS;
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

command void FennecData.load(void *ptr) {
	memcpy(ptr, call FennecData.getNxDataPtr(), call FennecData.getNxDataLen());
}

command void FennecData.update(void* net, uint8_t global_id) {
	bool diff = FALSE;
	void* fgd = call FennecData.getNxDataPtr();
	if (memcmp(net + global_data_info[global_id].offset, 
				fgd + global_data_info[global_id].offset,
				global_data_info[global_id].size)) {
		memcpy(fgd + global_data_info[global_id].offset, 
				net + global_data_info[global_id].offset,
				global_data_info[global_id].size);
		globalDataSyncWithNetwork(global_data_info[global_id].var_id);
		signal_global_update(global_data_info[global_id].var_id);
		diff = TRUE;
	}

	if (diff) {
		update_data_crc();
#ifdef __DBGS__FENNEC_CACHE__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printfGlobalData();
#endif
#endif
	}
}

command void FennecData.checkDataSeq(uint8_t msg_type) {
	if (LOW_DATA_ID(msg_type) != LOW_DATA_ID(current_data_crc)) {
		signal FennecData.resend();
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

#ifdef __DBGS__FENNEC_CACHE__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("Param.set[%u %u](%u ptr %u)\n", layer, process_id, name, size);
#endif
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

#ifdef __DBGS__FENNEC_CACHE__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("set variable %d\n", name);
#endif
#endif
	signal_global_update(name);

	globalDataSyncWithLocal(name);
	update_data_crc();

#ifdef __DBGS__FENNEC_CACHE__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printfGlobalData();
#endif
#endif
	signal FennecData.updated(name);
	return SUCCESS;
}

default event void Param.updated[uint8_t layer, process_t process_id](uint8_t var_id) {
}

}

