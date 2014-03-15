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
  * Fennec Fox Network Scheduler
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#include <Fennec.h>

module NetworkStateP @safe() {
provides interface SplitControl;
uses interface NetworkProcess;
uses interface Fennec;
}

implementation {


struct state* state_record;
process_t process_num = UNKNOWN;

task void start_protocol_stack() {
	state_record = call Fennec.getStateRecord();
	dbg("NetworkState", "NetworkStateP start_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);
	if (state_record->num_confs > process_num) {
		/* there are confs to start */
		dbg("NetworkState", "NetworkStateP call NetworkProcess.startConf(%d)",
				state_record->conf_list[conf]);
		call NetworkProcess.start(state_record->conf_list[process_num]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkState", "NetworkStateP finished starting NetworkProcess");
		process_num = UNKNOWN;
		signal SplitControl.startDone(SUCCESS);
	}
}

task void stop_protocol_stack() {
	state_record = call Fennec.getStateRecord();
	dbg("NetworkState", "NetworkStateP stop_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);

	if (state_record->num_confs > process_num) {
		/* there are confs to stop */
		dbg("NetworkState", "NetworkStateP call NetworkProcess.stopConf(%d)",
				state_record->conf_list[conf]);
		call NetworkProcess.stop(state_record->conf_list[process_num]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkState", "NetworkStateP finished stopping NetworkProcess");
		process_num = UNKNOWN;
		signal SplitControl.stopDone(SUCCESS);
	}
}

task void start_state() {
	process_num = 0;
	dbg("NetworkState", "NetworkStateP start_state() state = %d", 
						call Fennec.getStateId());
	post start_protocol_stack();
}

task void stop_state() {
	process_num = 0;
	dbg("NetworkState", "NetworkStateP stop_state() state = %d",
						call Fennec.getStateId());
	post stop_protocol_stack();
}

command error_t SplitControl.start() {
	dbg("NetworkState", "NetworkStateP SplitControl.start()");
	printf("NetworkState SplitControl.start()\n");
	post start_state();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("NetworkState", "NetworkStateP SplitControl.stop()");
	printf("NetworkState SplitControl.stop()\n");
	post stop_state();
	return SUCCESS;
}

event void NetworkProcess.startDone(error_t err) {
	dbg("NetworkState", "NetworkStateP NetworkProcess.startConfDone(%d)", err);
        if (err == SUCCESS) {
		process_num++;
        }
	post start_protocol_stack();
}

event void NetworkProcess.stopDone(error_t err) {
	dbg("NetworkState", "NetworkStateP NetworkProcess.stopConfDone(%d)", err);
        if (err == SUCCESS) {
		process_num++;
	}
	post stop_protocol_stack();
}

}
