#include <Fennec.h>
#include "capeRadioParams.h"

module capeRadioParamsC {
	 provides interface capeRadioParams;
}

implementation {

	command void capeRadioParams.send_status(uint16_t status_flag) {
	}

	command uint16_t capeRadioParams.get_sink_addr() {
		return capeRadio_data.sink_addr;
	}

	command error_t capeRadioParams.set_sink_addr(uint16_t new_sink_addr) {
		capeRadio_data.sink_addr = new_sink_addr;
		return SUCCESS;
	}

	command uint8_t capeRadioParams.get_channel() {
		return capeRadio_data.channel;
	}

	command error_t capeRadioParams.set_channel(uint8_t new_channel) {
		capeRadio_data.channel = new_channel;
		return SUCCESS;
	}

	command uint8_t capeRadioParams.get_power() {
		return capeRadio_data.power;
	}

	command error_t capeRadioParams.set_power(uint8_t new_power) {
		capeRadio_data.power = new_power;
		return SUCCESS;
	}

	command uint16_t capeRadioParams.get_remote_wakeup() {
		return capeRadio_data.remote_wakeup;
	}

	command error_t capeRadioParams.set_remote_wakeup(uint16_t new_remote_wakeup) {
		capeRadio_data.remote_wakeup = new_remote_wakeup;
		return SUCCESS;
	}

	command uint16_t capeRadioParams.get_delay_after_receive() {
		return capeRadio_data.delay_after_receive;
	}

	command error_t capeRadioParams.set_delay_after_receive(uint16_t new_delay_after_receive) {
		capeRadio_data.delay_after_receive = new_delay_after_receive;
		return SUCCESS;
	}

	command uint16_t capeRadioParams.get_backoff() {
		return capeRadio_data.backoff;
	}

	command error_t capeRadioParams.set_backoff(uint16_t new_backoff) {
		capeRadio_data.backoff = new_backoff;
		return SUCCESS;
	}

	command uint16_t capeRadioParams.get_min_backoff() {
		return capeRadio_data.min_backoff;
	}

	command error_t capeRadioParams.set_min_backoff(uint16_t new_min_backoff) {
		capeRadio_data.min_backoff = new_min_backoff;
		return SUCCESS;
	}

	command uint8_t capeRadioParams.get_ack() {
		return capeRadio_data.ack;
	}

	command error_t capeRadioParams.set_ack(uint8_t new_ack) {
		capeRadio_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t capeRadioParams.get_cca() {
		return capeRadio_data.cca;
	}

	command error_t capeRadioParams.set_cca(uint8_t new_cca) {
		capeRadio_data.cca = new_cca;
		return SUCCESS;
	}

	command uint8_t capeRadioParams.get_crc() {
		return capeRadio_data.crc;
	}

	command error_t capeRadioParams.set_crc(uint8_t new_crc) {
		capeRadio_data.crc = new_crc;
		return SUCCESS;
	}

}

