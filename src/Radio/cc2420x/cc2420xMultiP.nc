module cc2420xMultiP {
provides interface SplitControl[process_t process_id];
//provides interface RadioReceive[process_t process_id];
//uses interface RadioReceive as SubRadioReceive;
}

implementation {

process_t sp_proc = UNKNOWN;

task void startDone() {
	signal SplitControl.startDone[sp_proc](SUCCESS);
}


task void stopDone() {
	signal SplitControl.stopDone[sp_proc](SUCCESS);
}



command error_t SplitControl.start[process_t process_id]() {
	sp_proc = process_id;
	post startDone();
	return SUCCESS;
}

command error_t SplitControl.stop[process_t process_id]() {
	sp_proc = process_id;
	post stopDone();
	return SUCCESS;
}

/*
tasklet_async event bool RadioReceive.header(message_t* msg) {

}

tasklet_async event bool RadioReceive.receive(message_t* msg) {

}
*/


}
