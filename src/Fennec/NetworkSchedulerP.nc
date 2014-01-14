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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
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

module NetworkSchedulerP @safe() {
provides interface SplitControl;
uses interface ProtocolStack;
uses interface Fennec;
}

implementation {


struct state* state_record;
uint16_t conf = UNKNOWN_CONFIGURATION;

task void start_protocol_stack() {
	state_record = call Fennec.getStateRecord();
	dbg("NetworkScheduler", "NetworkSchedulerP start_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);
	if (state_record->num_confs > conf) {
		/* there are confs to start */
		dbg("NetworkScheduler", "NetworkSchedulerP call ProtocolStack.startConf(%d)",
				state_record->conf_list[conf]);
		call ProtocolStack.startConf(state_record->conf_list[conf]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkScheduler", "NetworkSchedulerP finished starting ProtocolStack");
		conf = UNKNOWN_CONFIGURATION;
		signal SplitControl.startDone(SUCCESS);
	}
}

task void stop_protocol_stack() {
	state_record = call Fennec.getStateRecord();
	dbg("NetworkScheduler", "NetworkSchedulerP stop_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);

	if (state_record->num_confs > conf) {
		/* there are confs to stop */
		dbg("NetworkScheduler", "NetworkSchedulerP call ProtocolStack.stopConf(%d)",
				state_record->conf_list[conf]);
		call ProtocolStack.stopConf(state_record->conf_list[conf]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkScheduler", "NetworkSchedulerP finished stopping ProtocolStack");
		conf = UNKNOWN_CONFIGURATION;
		signal SplitControl.stopDone(SUCCESS);
	}
}

task void start_state() {
	conf = 0;
	dbg("NetworkScheduler", "NetworkSchedulerP start_state() state = %d", 
						call Fennec.getStateId());
	post start_protocol_stack();
}

task void stop_state() {
	conf = 0;
	dbg("NetworkScheduler", "NetworkSchedulerP stop_state() state = %d",
						call Fennec.getStateId());
	post stop_protocol_stack();
}

command error_t SplitControl.start() {
	dbg("NetworkScheduler", "NetworkSchedulerP SplitControl.start()");
	post start_state();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("NetworkScheduler", "NetworkSchedulerP SplitControl.stop()");
	post stop_state();
	return SUCCESS;
}

event void ProtocolStack.startConfDone(error_t err) {
	dbg("NetworkScheduler", "NetworkSchedulerP ProtocolStack.startConfDone(%d)", err);
        if (err == SUCCESS) {
		conf++;
        }
	post start_protocol_stack();
}

event void ProtocolStack.stopConfDone(error_t err) {
	dbg("NetworkScheduler", "NetworkSchedulerP ProtocolStack.stopConfDone(%d)", err);
        if (err == SUCCESS) {
		conf++;
	}
	post stop_protocol_stack();
}

}
