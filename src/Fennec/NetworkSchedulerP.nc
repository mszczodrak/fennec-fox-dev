#include <Fennec.h>

module NetworkSchedulerP @safe() {

provides interface SimpleStart;

uses interface Mgmt as ProtocolStack;
uses interface Mgmt as EventsMgmt;
uses interface EventCache;
uses interface PolicyCache;

}

implementation {

uint8_t num_of_proc = 0;

command void SimpleStart.start() {
	num_of_proc = 0;

	dbg("NetworkScheduler", "NetworkScheduler SimpleStart.start()");

	signal SimpleStart.startDone(SUCCESS);
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


event void ProtocolStack.startDone(error_t err) {
        if (err != SUCCESS) {
                call ProtocolStack.start();
                return;
        }
}

event void ProtocolStack.stopDone(error_t err) {
        if (err != SUCCESS) {
                call ProtocolStack.stop();
                return;
        }
}

}
