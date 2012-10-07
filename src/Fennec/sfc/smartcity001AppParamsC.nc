#include <Fennec.h>
#include "smartcity001AppParams.h"

module smartcity001AppParamsC {
	 provides interface smartcity001AppParams;
}

implementation {

	command void smartcity001AppParams.send_status(uint16_t status_flag) {
	}

	command uint16_t smartcity001AppParams.get_delay_ms() {
		return smartcity001App_data.delay_ms;
	}

	command error_t smartcity001AppParams.set_delay_ms(uint16_t new_delay_ms) {
		smartcity001App_data.delay_ms = new_delay_ms;
		return SUCCESS;
	}

	command uint16_t smartcity001AppParams.get_delay_scale() {
		return smartcity001App_data.delay_scale;
	}

	command error_t smartcity001AppParams.set_delay_scale(uint16_t new_delay_scale) {
		smartcity001App_data.delay_scale = new_delay_scale;
		return SUCCESS;
	}

	command uint16_t smartcity001AppParams.get_src() {
		return smartcity001App_data.src;
	}

	command error_t smartcity001AppParams.set_src(uint16_t new_src) {
		smartcity001App_data.src = new_src;
		return SUCCESS;
	}

	command uint16_t smartcity001AppParams.get_dest() {
		return smartcity001App_data.dest;
	}

	command error_t smartcity001AppParams.set_dest(uint16_t new_dest) {
		smartcity001App_data.dest = new_dest;
		return SUCCESS;
	}

	command uint8_t smartcity001AppParams.get_sensor() {
		return smartcity001App_data.sensor;
	}

	command error_t smartcity001AppParams.set_sensor(uint8_t new_sensor) {
		smartcity001App_data.sensor = new_sensor;
		return SUCCESS;
	}

}

