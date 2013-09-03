
#include <sim_irradiance.h>
#include <sim_seh.h>
#include <sim_log.h>

module IrradianceModelP {
provides interface IrradianceModel;
uses interface Timer<TMilli>;
}

implementation {

uint64_t harvesting_period = 10;
bool running = FALSE;
float lastTrace;

void sim_request_harvesting();
void sim_irradiance_receive_handle(sim_event_t *evt);
void sim_watt_receive(sim_event_t *evt);


command error_t IrradianceModel.startHarvesting() {
	running = TRUE;
	sim_request_harvesting();
	return SUCCESS;
}

command error_t IrradianceModel.stopHarvesting() {
	running = FALSE;
	return SUCCESS;
}


event void Timer.fired() {
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
	evt->time += (harvesting_period * CAPE_TO_SECONDS);	/* irradiance is sampled every harvesting_period sec */
	sim_queue_insert(evt);
}


void sim_irradiance_receive_handle(sim_event_t *evt) {
	float watt;
	lastTrace = sim_irradiance_trace(evt->mote);	/* irradiance perm m^2 */	


	sim_seh_solar_cell_size(); /* in cm^2 */

	watt = lastTrace * 
		(sim_seh_solar_cell_size() / 10000.0) * 
		(sim_seh_solar_cell_efficiency() / 100.0);

	dbg("IrradianceModel", "IrradianceModel received %f", lastTrace);

	if (running) {
		sim_request_harvesting();
	}
}






}
