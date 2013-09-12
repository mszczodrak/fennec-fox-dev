module EnergyP {
provides interface SimpleStart;

provides interface SimDynamicEnergy;

uses interface SplitControl;
}

implementation {

#define CAPE_MAX_SIM_ENERGY 4000
#define CAPE_MIN_SIM_ENERGY 0

double total_joules = 0;

command void SimpleStart.start() {
	total_joules = 0;
	call SplitControl.start();
}


event void SplitControl.startDone(error_t err) {
	signal SimpleStart.startDone(err);
}

event void SplitControl.stopDone(error_t err) {

}

command error_t SimDynamicEnergy.add(double joules) {
	total_joules += joules;
	if (joules <= CAPE_MAX_SIM_ENERGY) {
		dbg("Energy", "Energy SimDynamicEnergy.add(%f)  total: %f", joules, total_joules);
		return SUCCESS;
	} else {
		joules = CAPE_MAX_SIM_ENERGY;
		dbg("Energy", "Energy SimDynamicEnergy.add(%f)  total: %f", joules, total_joules);
		return FAIL;
	}
}

command error_t SimDynamicEnergy.del(double joules) {
	total_joules -= joules;
	if (joules >= CAPE_MIN_SIM_ENERGY) {
		dbg("Energy", "Energy SimDynamicEnergy.del(%f)  total: %f", joules, total_joules);
		return SUCCESS;
	} else {
		joules = CAPE_MIN_SIM_ENERGY;
		dbg("Energy", "Energy SimDynamicEnergy.del(%f)  total: %f", joules, total_joules);
		return FAIL;
	}
}

}
