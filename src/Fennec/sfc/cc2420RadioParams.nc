interface cc2420RadioParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint8_t get_channel();
	command error_t set_channel(uint8_t new_channel);
	command uint8_t get_power();
	command error_t set_power(uint8_t new_power);
	command uint8_t get_ack();
	command error_t set_ack(uint8_t new_ack);
	command uint8_t get_crc();
	command error_t set_crc(uint8_t new_crc);
}

