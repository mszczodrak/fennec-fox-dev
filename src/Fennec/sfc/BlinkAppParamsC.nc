#include <Fennec.h>
#include "BlinkAppParams.h"

module BlinkAppParamsC {
	 provides interface BlinkAppParams;
}

implementation {

	command void BlinkAppParams.send_status(uint16_t status_flag) {
	}

	command uint8_t BlinkAppParams.get_led() {
		return BlinkApp_data.led;
	}

	command error_t BlinkAppParams.set_led(uint8_t new_led) {
		BlinkApp_data.led = new_led;
		return SUCCESS;
	}

	command uint16_t BlinkAppParams.get_delay() {
		return BlinkApp_data.delay;
	}

	command error_t BlinkAppParams.set_delay(uint16_t new_delay) {
		BlinkApp_data.delay = new_delay;
		return SUCCESS;
	}

}

