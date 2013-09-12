interface Irradiance {
command error_t startHarvesting();
command error_t stopHarvesting();

event void harvested(double watt);
/* 	
	Signals energy harvested over the 1 minute period for a
	solar cell with 1m^2 size and 100% efficiency.
*/

command uint16_t getHarvestingPeriodSec();
}
