module SolarCellP {

provides interface SplitControl;
provides interface SolarCell;

uses interface IrradianceModel;
}

implementation {

error_t err;

task void start_done() {
	signal SplitControl.startDone(err);
}

task void stop_done() {
	signal SplitControl.stopDone(err);
}

command error_t SplitControl.start() {
	err = call IrradianceModel.startHarvesting();
	post start_done();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	err = call IrradianceModel.stopHarvesting();
	post stop_done();
	return SUCCESS;
}

command uint8_t SolarCell.getEfficiency() {
	return 0;
}

command uint8_t SolarCell.getArea() {
	return 0;
}

event void IrradianceModel.harvested(uint16_t watt) {

}

}
