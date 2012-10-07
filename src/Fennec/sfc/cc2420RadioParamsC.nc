#include <Fennec.h>
#include "cc2420RadioParams.h"

module cc2420RadioParamsC {
	 provides interface cc2420RadioParams;
}

implementation {

	command void cc2420RadioParams.send_status(uint16_t status_flag) {
	}

	command uint8_t cc2420RadioParams.get_channel() {
		return cc2420Radio_data.channel;
	}

	command error_t cc2420RadioParams.set_channel(uint8_t new_channel) {
		cc2420Radio_data.channel = new_channel;
		return SUCCESS;
	}

	command uint8_t cc2420RadioParams.get_power() {
		return cc2420Radio_data.power;
	}

	command error_t cc2420RadioParams.set_power(uint8_t new_power) {
		cc2420Radio_data.power = new_power;
		return SUCCESS;
	}

	command uint8_t cc2420RadioParams.get_ack() {
		return cc2420Radio_data.ack;
	}

	command error_t cc2420RadioParams.set_ack(uint8_t new_ack) {
		cc2420Radio_data.ack = new_ack;
		return SUCCESS;
	}

	command uint8_t cc2420RadioParams.get_crc() {
		return cc2420Radio_data.crc;
	}

	command error_t cc2420RadioParams.set_crc(uint8_t new_crc) {
		cc2420Radio_data.crc = new_crc;
		return SUCCESS;
	}

}

