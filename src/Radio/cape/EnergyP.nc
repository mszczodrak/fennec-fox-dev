module EnergyP {
provides interface SimpleStart;
uses interface SplitControl as EnergySrcCtrl;
}

implementation {

command void SimpleStart.start() {

	call EnergySrcCtrl.start();

}


event void EnergySrcCtrl.startDone(error_t err) {
	signal SimpleStart.startDone(err);
}

event void EnergySrcCtrl.stopDone(error_t err) {

}

}
