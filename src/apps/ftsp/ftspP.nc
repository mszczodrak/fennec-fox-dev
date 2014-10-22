generic module ftspP(uint8_t process) {
provides interface SplitControl;
uses interface Param;

uses interface SplitControl as SubSplitControl;
uses interface Timer<TMilli>;
uses interface GlobalTime<TMilli>;

}

implementation {

uint32_t sleep_time;

command error_t SplitControl.start() {
	call Param.get(SLEEP_TIME, &sleep_time, sizeof(sleep_time));

	//call Timer.startPeriodic(send_delay);

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Counter start()\n", process);
#else
	//call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	call Timer.stop();
	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t err) {
	signal SplitControl.startDone(err);
}

event void SubSplitControl.stopDone(error_t err) {
	signal SplitControl.stopDone(err);
}

event void Timer.fired() {


}

event void Param.updated(uint8_t var_id) {

}


}
