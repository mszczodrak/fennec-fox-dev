module SolarCellP {

provides interface SplitControl;
provides interface SolarCell;
uses interface SimDynamicEnergy;

uses interface Irradiance;
uses interface SolarCell as SubSolarCell;

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
	err = call Irradiance.startHarvesting();
	post start_done();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	err = call Irradiance.stopHarvesting();
	post stop_done();
	return SUCCESS;
}

command double SolarCell.getEfficiency() {
	return call SubSolarCell.getEfficiency();
}

command double SolarCell.getArea() {
	return call SubSolarCell.getArea();
}

event void Irradiance.harvested(double watt) {
	double new_watt;
	double joule;
	/*
	convert the trace reading into the watt energy harvested by 
	the simulated solar cell, which is not necessary 1m^2 and
	100% efficient
	*/

	new_watt = watt * call SolarCell.getEfficiency()  * 
			call SolarCell.getArea() ;

	//dbg("SolarCell", "SolarCell watt %f", new_watt);

	joule = new_watt * call Irradiance.getHarvestingPeriodSec();
	
	dbg("SolarCell", "SolarCell joule %f", joule);
	
	call SimDynamicEnergy.add(joule);
}


}
