#include "irradiance_trace.h"

module IrradianceTraceP {
provides interface Irradiance;
uses interface Timer<TMilli>;
}

implementation {


#define HARVESTING_PERIOD_SEC   60
#define IRRADIANCE_TRACE_LEN sizeof(trace) / sizeof(float)

bool running = FALSE;
uint32_t index = 0;

command error_t Irradiance.startHarvesting() {
	dbg("Irradiance", "Irradiance trace len %d", IRRADIANCE_TRACE_LEN);
	index = 0;
	running = TRUE;
	if (IRRADIANCE_TRACE_LEN > 0) {
		call Timer.startPeriodic(HARVESTING_PERIOD_SEC * 1000);
        	return SUCCESS;
	} else {
		return FAIL;
	}
}

command error_t Irradiance.stopHarvesting() {
	running = FALSE;
	call Timer.stop();
	return SUCCESS;
}

command uint16_t Irradiance.getHarvestingPeriodSec() {
	return HARVESTING_PERIOD_SEC;
}

event void Timer.fired() {
	signal Irradiance.harvested((double)trace[index]);

	index++;

	if (index >= IRRADIANCE_TRACE_LEN) {
		index = 0;
	}
}

}
