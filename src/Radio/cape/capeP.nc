generic module capeP(process_t process) {
provides interface SplitControl;
uses interface capeParams;
}
implementation {

task void startDone() {
	signal SplitControl.startDone(SUCCESS);
}

task void stopDone() {
	signal SplitControl.stopDone(SUCCESS);
}

command error_t SplitControl.start() {
	post startDone();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	post stopDone();
	return SUCCESS;
}

}
