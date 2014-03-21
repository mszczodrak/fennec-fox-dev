generic module nullRadioP(process_t process) {
provides interface SplitControl;
uses interface nullRadioParams;
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
