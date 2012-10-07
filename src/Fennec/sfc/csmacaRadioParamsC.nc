#include <Fennec.h>
#include "csmacaRadioParams.h"

module csmacaRadioParamsC {
	 provides interface csmacaRadioParams;
}

implementation {

	command void csmacaRadioParams.send_status(uint16_t status_flag) {
	}

	command uint16_t csmacaRadioParams.get_sink_addr() {
		return csmacaRadio_data.sink_addr;
	}

	command error_t csmacaRadioParams.set_sink_addr(uint16_t new_sink_addr) {
		csmacaRadio_data.sink_addr = new_sink_addr;
		return SUCCESS;
	}

	command uint8_t csmacaRadioParams.get_channel() {
		return csmacaRadio_data.channel;
	}

	command error_t csmacaRadioParams.set_channel(uint8_t new_channel) {
		csmacaRadio_data.channel = new_channel;
		return SUCCESS;
	}

	command uint8_t csmacaRadioParams.get_power() {
		return csmacaRadio_data.power;
	}

	command error_t csmacaRadioParams.set_power(uint8_t new_power) {
		csmacaRadio_data.power = new_power;
		return SUCCESS;
	}

	command uint16_t csmacaRadioParams.get_remote_wakeup() {
		return csmacaRadio_data.remote_wakeup;
	}

	command error_t csmacaRadioParams.set_remote_wakeup(uint16_t new_remote_wakeup) {
		csmacaRadio_data.remote_wakeup = new_remote_wakeup;
		return SUCCESS;
	}

	command uint16_t csmacaRadioParams.get_delay_after_receive() {
		return csmacaRadio_data.delay_after_receive;
	}

	command error_t csmacaRadioParams.set_delay_after_receive(uint16_t new_delay_after_receive) {
		csmacaRadio_data.delay_after_receive = new_delay_after_receive;
		return SUCCESS;
	}

	command uint16_t csmacaRadioParams.get_backoff() {
		return csmacaRadio_data.backoff;
	}

	command error_t csmacaRadioParams.set_backoff(uint16_t new_backoff) {
		csmacaRadio_data.backoff = new_backoff;
		return SUCCESS;
	}

	command uint16_t csmacaRadioParams.get_min_backoff() {
		return csmacaRadio_data.min_backoff;
	}

	command error_t csmacaRadioParams.set_min_backoff(uint16_t new_min_backoff) {
		csmacaRadio_data.min_backoff = new_min_backoff;
		return SUCCESS;
	}

	command uint8_t csmacaRadioParams.get_ack() {
		return csmacaRadio_data.ack;
	}

	command error_t csmacaRadioParams.set_ack(uint8_t new_ack) {
		csmacaRadio_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t csmacaRadioParams.get_cca() {
		return csmacaRadio_data.cca;
	}

	command error_t csmacaRadioParams.set_cca(uint8_t new_cca) {
		csmacaRadio_data.cca = new_cca;
		return SUCCESS;
	}

	command uint8_t csmacaRadioParams.get_crc() {
		return csmacaRadio_data.crc;
	}

	command error_t csmacaRadioParams.set_crc(uint8_t new_crc) {
		csmacaRadio_data.crc = new_crc;
		return SUCCESS;
	}

}

