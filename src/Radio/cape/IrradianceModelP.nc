
#include <sim_irradiance.h>
#include <sim_seh.h>
#include <sim_log.h>

module IrradianceModelP {
provides interface Irradiance;
}

implementation {

#define HARVESTING_PERIOD_SEC	60

bool running = FALSE;

void sim_request_harvesting();
void sim_irradiance_receive_handle(sim_event_t *evt);
void sim_watt_receive(sim_event_t *evt);

command error_t Irradiance.startHarvesting() {
	running = TRUE;
	sim_request_harvesting();
	return SUCCESS;
}

command error_t Irradiance.stopHarvesting() {
	running = FALSE;
	return SUCCESS;
}

command uint16_t Irradiance.getHarvestingPeriodSec() {
	return HARVESTING_PERIOD_SEC;
}

void sim_request_harvesting() {
	sim_event_t *evt = (sim_event_t*)malloc(sizeof(sim_event_t));
	sim_time_t endTime = sim_time();

	evt->mote = sim_node();
	evt->time = endTime;
	evt->handle = sim_irradiance_receive_handle;
	evt->cleanup = sim_queue_cleanup_event;
	evt->cancelled = 0;
	evt->force = 1;
	evt->data = NULL;

	/* add time delay */
	evt->time += (HARVESTING_PERIOD_SEC * CAPE_SIM_TO_SECONDS);	/* irradiance is sampled every HARVESTING_PERIOD_SEC sec */
	sim_queue_insert(evt);
}

void sim_irradiance_receive_handle(sim_event_t *evt) {
	double lastTrace = sim_irradiance_trace(evt->mote);	/* irradiance perm m^2 */	

	dbg("IrradianceModel", "IrradianceModel watt %f", lastTrace);
	signal Irradiance.harvested(lastTrace);

	if (running) {
		sim_request_harvesting();
	}
}






}
