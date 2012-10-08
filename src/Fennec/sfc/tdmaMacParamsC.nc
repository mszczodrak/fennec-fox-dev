#include <Fennec.h>
#include "tdmaMacParams.h"

module tdmaMacParamsC {
	 provides interface tdmaMacParams;
}

implementation {

	command void tdmaMacParams.send_status(uint16_t status_flag) {
	}

	command uint16_t tdmaMacParams.get_root_addr() {
		return tdmaMac_data.root_addr;
	}

	command error_t tdmaMacParams.set_root_addr(uint16_t new_root_addr) {
		tdmaMac_data.root_addr = new_root_addr;
		return SUCCESS;
	}

	command uint32_t tdmaMacParams.get_active_time() {
		return tdmaMac_data.active_time;
	}

	command error_t tdmaMacParams.set_active_time(uint32_t new_active_time) {
		tdmaMac_data.active_time = new_active_time;
		return SUCCESS;
	}

	command uint32_t tdmaMacParams.get_sleep_time() {
		return tdmaMac_data.sleep_time;
	}

	command error_t tdmaMacParams.set_sleep_time(uint32_t new_sleep_time) {
		tdmaMac_data.sleep_time = new_sleep_time;
		return SUCCESS;
	}

	command uint16_t tdmaMacParams.get_backoff() {
		return tdmaMac_data.backoff;
	}

	command error_t tdmaMacParams.set_backoff(uint16_t new_backoff) {
		tdmaMac_data.backoff = new_backoff;
		return SUCCESS;
	}

	command uint16_t tdmaMacParams.get_min_backoff() {
		return tdmaMac_data.min_backoff;
	}

	command error_t tdmaMacParams.set_min_backoff(uint16_t new_min_backoff) {
		tdmaMac_data.min_backoff = new_min_backoff;
		return SUCCESS;
	}

	command uint8_t tdmaMacParams.get_ack() {
		return tdmaMac_data.ack;
	}

	command error_t tdmaMacParams.set_ack(uint8_t new_ack) {
		tdmaMac_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t tdmaMacParams.get_cca() {
		return tdmaMac_data.cca;
	}

	command error_t tdmaMacParams.set_cca(uint8_t new_cca) {
		tdmaMac_data.cca = new_cca;
		return SUCCESS;
	}

	command uint8_t tdmaMacParams.get_crc() {
		return tdmaMac_data.crc;
	}

	command error_t tdmaMacParams.set_crc(uint8_t new_crc) {
		tdmaMac_data.crc = new_crc;
		return SUCCESS;
	}

}

