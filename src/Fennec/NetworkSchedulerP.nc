#include <Fennec.h>

module NetworkSchedulerP @safe() {

provides interface SimpleStart;

uses interface ProtocolStack;
uses interface Mgmt as EventsMgmt;
uses interface EventCache;
uses interface PolicyCache;

}

implementation {

uint8_t num_of_proc = 0;
uint8_t state = S_STOPPED;

uint16_t processing_state;
struct network_state* state_record;
uint16_t conf = UNKNOWN_CONFIGURATION;

task void start_protocol_stack() {
	processing_state = call PolicyCache.getNetworkState();
	dbg("NetworkScheduler", "NetworkScheduler start_protocol_stack network_state = %d", processing_state);
	state_record = call PolicyCache.getStateRecord(processing_state);
	dbg("NetworkScheduler", "NetworkScheduler start_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);

	if (conf == UNKNOWN_CONFIGURATION) {
		dbg("NetworkScheduler", "NetworkScheduler first time starting, rest conf");
		/* this is first time we are starting configuration of the stack */
		// TODO : normally start from 0, but to skip POLICY, start from 1
		//conf = 0;
		conf = 1;
	}

	if (state_record->num_confs > conf) {
		/* there are confs to start */
		dbg("NetworkScheduler", "NetworkScheduler call ProtocolStack.startConf(%d)",
				state_record->conf_ids[conf]);
		call ProtocolStack.startConf(state_record->conf_ids[conf]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkScheduler", "NetworkScheduler finished starting ProtocolStack");
		conf = UNKNOWN_CONFIGURATION;

	}
	
}



task void stop_protocol_stack() {
	processing_state = call PolicyCache.getNodeState();
	dbg("NetworkScheduler", "NetworkScheduler start_protocol_stack network_state = %d", processing_state);
	state_record = call PolicyCache.getStateRecord(processing_state);
	dbg("NetworkScheduler", "NetworkScheduler start_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);

	

}


command void SimpleStart.start() {
	num_of_proc = 0;
	conf = UNKNOWN_CONFIGURATION;

	dbg("NetworkScheduler", "NetworkScheduler SimpleStart.start()");

	signal SimpleStart.startDone(SUCCESS);
	state = S_STARTING;
	post start_protocol_stack();
}

event void PolicyCache.newConf(conf_t new_conf) {
//      set_new_state(new_conf, configuration_seq + 1);
}

event void PolicyCache.wrong_conf() {
        //reset_control();
}

event void EventsMgmt.startDone(error_t err) {
/*
        if (err != SUCCESS) {
                call EventsMgmt.start();
                return;
        }
        call ProtocolStack.start();
*/
}


event void EventsMgmt.stopDone(error_t err) {
/*
        if (err != SUCCESS) {
                call EventsMgmt.stop();
                return;
        }
        reset_control();
*/
}


event void ProtocolStack.startConfDone(error_t err) {
	dbg("NetworkScheduler", "ProtocolStack.startConfDone(%d)", err);
        if (err == SUCCESS) {
		conf++;
        }
	post start_protocol_stack();
}

event void ProtocolStack.stopConfDone(error_t err) {
	dbg("NetworkScheduler", "ProtocolStack.stopConfDone(%d)", err);
        if (err != SUCCESS) {
//                call ProtocolStack.stop();
                return;
        }
}

}
