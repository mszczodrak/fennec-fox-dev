#include <Fennec.h>
#include "cuMacParams.h"

module cuMacParamsC {
	 provides interface cuMacParams;
}

implementation {

	command void cuMacParams.send_status(uint16_t status_flag) {
	}

	command uint16_t cuMacParams.get_backoff() {
		return cuMac_data.backoff;
	}

	command error_t cuMacParams.set_backoff(uint16_t new_backoff) {
		cuMac_data.backoff = new_backoff;
		return SUCCESS;
	}

	command uint16_t cuMacParams.get_min_backoff() {
		return cuMac_data.min_backoff;
	}

	command error_t cuMacParams.set_min_backoff(uint16_t new_min_backoff) {
		cuMac_data.min_backoff = new_min_backoff;
		return SUCCESS;
	}

	command uint8_t cuMacParams.get_ack() {
		return cuMac_data.ack;
	}

	command error_t cuMacParams.set_ack(uint8_t new_ack) {
		cuMac_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t cuMacParams.get_cca() {
		return cuMac_data.cca;
	}

	command error_t cuMacParams.set_cca(uint8_t new_cca) {
		cuMac_data.cca = new_cca;
		return SUCCESS;
	}

	command uint8_t cuMacParams.get_crc() {
		return cuMac_data.crc;
	}

	command error_t cuMacParams.set_crc(uint8_t new_crc) {
		cuMac_data.crc = new_crc;
		return SUCCESS;
	}

}

