#include <Fennec.h>
#include "CounterAppParams.h"

module CounterAppParamsC {
	 provides interface CounterAppParams;
}

implementation {

	command void CounterAppParams.send_status(uint16_t status_flag) {
	}

	command uint16_t CounterAppParams.get_delay() {
		return CounterApp_data.delay;
	}

	command error_t CounterAppParams.set_delay(uint16_t new_delay) {
		CounterApp_data.delay = new_delay;
		return SUCCESS;
	}

	command uint16_t CounterAppParams.get_delay_scale() {
		return CounterApp_data.delay_scale;
	}

	command error_t CounterAppParams.set_delay_scale(uint16_t new_delay_scale) {
		CounterApp_data.delay_scale = new_delay_scale;
		return SUCCESS;
	}

	command uint16_t CounterAppParams.get_src() {
		return CounterApp_data.src;
	}

	command error_t CounterAppParams.set_src(uint16_t new_src) {
		CounterApp_data.src = new_src;
		return SUCCESS;
	}

	command uint16_t CounterAppParams.get_dest() {
		return CounterApp_data.dest;
	}

	command error_t CounterAppParams.set_dest(uint16_t new_dest) {
		CounterApp_data.dest = new_dest;
		return SUCCESS;
	}

}

