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

	command uint16_t tdmaMacParams.get_frame_size() {
		return tdmaMac_data.frame_size;
	}

	command error_t tdmaMacParams.set_frame_size(uint16_t new_frame_size) {
		tdmaMac_data.frame_size = new_frame_size;
		return SUCCESS;
	}

	command uint16_t tdmaMacParams.get_node_time() {
		return tdmaMac_data.node_time;
	}

	command error_t tdmaMacParams.set_node_time(uint16_t new_node_time) {
		tdmaMac_data.node_time = new_node_time;
		return SUCCESS;
	}

	command uint16_t tdmaMacParams.get_radio_off_time() {
		return tdmaMac_data.radio_off_time;
	}

	command error_t tdmaMacParams.set_radio_off_time(uint16_t new_radio_off_time) {
		tdmaMac_data.radio_off_time = new_radio_off_time;
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

