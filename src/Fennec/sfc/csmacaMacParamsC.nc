#include <Fennec.h>
#include "csmacaMacParams.h"

module csmacaMacParamsC {
	 provides interface csmacaMacParams;
}

implementation {

	command void csmacaMacParams.send_status(uint16_t status_flag) {
	}

	command uint16_t csmacaMacParams.get_sink_addr() {
		return csmacaMac_data.sink_addr;
	}

	command error_t csmacaMacParams.set_sink_addr(uint16_t new_sink_addr) {
		csmacaMac_data.sink_addr = new_sink_addr;
		return SUCCESS;
	}

	command uint16_t csmacaMacParams.get_delay_after_receive() {
		return csmacaMac_data.delay_after_receive;
	}

	command error_t csmacaMacParams.set_delay_after_receive(uint16_t new_delay_after_receive) {
		csmacaMac_data.delay_after_receive = new_delay_after_receive;
		return SUCCESS;
	}

	command uint16_t csmacaMacParams.get_backoff() {
		return csmacaMac_data.backoff;
	}

	command error_t csmacaMacParams.set_backoff(uint16_t new_backoff) {
		csmacaMac_data.backoff = new_backoff;
		return SUCCESS;
	}

	command uint16_t csmacaMacParams.get_min_backoff() {
		return csmacaMac_data.min_backoff;
	}

	command error_t csmacaMacParams.set_min_backoff(uint16_t new_min_backoff) {
		csmacaMac_data.min_backoff = new_min_backoff;
		return SUCCESS;
	}

	command uint8_t csmacaMacParams.get_ack() {
		return csmacaMac_data.ack;
	}

	command error_t csmacaMacParams.set_ack(uint8_t new_ack) {
		csmacaMac_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t csmacaMacParams.get_cca() {
		return csmacaMac_data.cca;
	}

	command error_t csmacaMacParams.set_cca(uint8_t new_cca) {
		csmacaMac_data.cca = new_cca;
		return SUCCESS;
	}

	command uint8_t csmacaMacParams.get_crc() {
		return csmacaMac_data.crc;
	}

	command error_t csmacaMacParams.set_crc(uint8_t new_crc) {
		csmacaMac_data.crc = new_crc;
		return SUCCESS;
	}

}

