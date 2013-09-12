module SolarCellP {

provides interface SplitControl;
provides interface SolarCell;
uses interface SimDynamicEnergy;

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
	return sim_seh_solar_cell_efficiency();
}

command uint8_t SolarCell.getArea() {
	return sim_seh_solar_cell_size();
}

event void IrradianceModel.harvested(double watt) {
	double new_watt;
	double joule;
	/*
	convert the trace reading into the watt energy harvested by 
	the simulated solar cell, which is not necessary 1m^2 and
	100% efficient
	*/

	new_watt = watt * sim_seh_solar_cell_size() * 
			sim_seh_solar_cell_efficiency();

	//dbg("SolarCell", "SolarCell watt %f", new_watt);

	joule = new_watt * call IrradianceModel.getHarvestingPeriodSec();
	
	dbg("SolarCell", "SolarCell joule %f", joule);
	
	call SimDynamicEnergy.add(joule);
}


}
