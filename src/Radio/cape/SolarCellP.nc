module SolarCellP {

provides interface SplitControl;
provides interface SolarCell;

uses interface IrradianceModel;
}

implementation {

error_t err;

double joule_charge = 0;

task void start_done() {
	signal SplitControl.startDone(err);
}

task void stop_done() {
	signal SplitControl.stopDone(err);
}

command error_t SplitControl.start() {
	joule_charge = 0;
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

event void IrradianceModel.harvestedW(double watt) {

}

event void IrradianceModel.harvestedJ(double joule) {
	joule_charge += joule;
}

}
