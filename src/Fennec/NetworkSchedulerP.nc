#include <Fennec.h>

module NetworkSchedulerP @safe() {

provides interface SplitControl;
provides interface SimpleStart;

uses interface ProtocolStack;
uses interface EventCache;
uses interface PolicyCache;

}

implementation {


uint16_t processing_state;
struct state* state_record;
uint16_t conf = UNKNOWN_CONFIGURATION;

task void start_protocol_stack();
task void stop_protocol_stack();


task void start_done() {


}


task void start_state() {
	conf = 0;
	processing_state = call PolicyCache.getNetworkState();
	dbg("NetworkScheduler", "NetworkScheduler start_state() state = %d", processing_state);
	post start_protocol_stack();
}

task void stop_state() {
	conf = 0;
	processing_state = call PolicyCache.getNetworkState();
	dbg("NetworkScheduler", "NetworkScheduler stop_state() state = %d", processing_state);
	post stop_protocol_stack();
}

task void start_protocol_stack() {
	state_record = call PolicyCache.getStateRecord(processing_state);
	dbg("NetworkScheduler", "NetworkScheduler start_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);
	if (state_record->num_confs > conf) {
		/* there are confs to start */
		dbg("NetworkScheduler", "NetworkScheduler call ProtocolStack.startConf(%d)",
				state_record->conf_list[conf]);
		call ProtocolStack.startConf(state_record->conf_list[conf]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkScheduler", "NetworkScheduler finished starting ProtocolStack");
		conf = UNKNOWN_CONFIGURATION;
	}
}

task void stop_protocol_stack() {
	state_record = call PolicyCache.getStateRecord(processing_state);
	dbg("NetworkScheduler", "NetworkScheduler stop_protocol_stack id = %d, num_confs = %d", 
		state_record->state_id, state_record->num_confs);

	if (state_record->num_confs > conf) {
		/* there are confs to stop */
		dbg("NetworkScheduler", "NetworkScheduler call ProtocolStack.stopConf(%d)",
				state_record->conf_list[conf]);
		call ProtocolStack.stopConf(state_record->conf_list[conf]);		

	} else {
		/* that's all folks, all configurations are running */
		dbg("NetworkScheduler", "NetworkScheduler finished stopping ProtocolStack");
		conf = UNKNOWN_CONFIGURATION;
	}
}

command error_t SplitControl.start() {
	post start_state();
}

command error_t SplitControl.stop() {
	post stop_state();
}

command void SimpleStart.start() {
	dbg("NetworkScheduler", "NetworkScheduler SimpleStart.start()");
	post start_state();
	signal SimpleStart.startDone(SUCCESS);
}

event void PolicyCache.newConf(conf_t new_conf) {
//      set_new_state(new_conf, configuration_seq + 1);
}

event void PolicyCache.wrong_conf() {
        //reset_control();
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
