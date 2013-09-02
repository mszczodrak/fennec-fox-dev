
#include <sim_irradiance.h>
#include <sim_seh.h>
#include <sim_log.h>

module IrradianceModelP {
provides interface IrradianceModel;
uses interface Timer<TMilli>;
}

implementation {

uint64_t harvesting_period = 10;

void sim_request_harvesting();
void sim_irradiance_receive_handle(sim_event_t *evt);

void sim_irradiance_receive_handle(sim_event_t *evt) {

	dbg("IrradianceModel", "IrradianceModel received");

	sim_request_harvesting();
	
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
	evt->data = 0;

	/* add time delay */
	evt->time += (harvesting_period * CAPE_TO_SECONDS);	/* irradiance is sampled every harvesting_period sec */
	sim_queue_insert(evt);
}


command error_t IrradianceModel.startHarvesting() {
	sim_request_harvesting();
	return SUCCESS;
}

command error_t IrradianceModel.stopHarvesting() {
	return SUCCESS;
}


event void Timer.fired() {



}


}
