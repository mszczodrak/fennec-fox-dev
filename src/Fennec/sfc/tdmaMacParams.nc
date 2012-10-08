interface tdmaMacParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint16_t get_root_addr();
	command error_t set_root_addr(uint16_t new_root_addr);
	command uint32_t get_active_time();
	command error_t set_active_time(uint32_t new_active_time);
	command uint32_t get_sleep_time();
	command error_t set_sleep_time(uint32_t new_sleep_time);
	command uint16_t get_backoff();
	command error_t set_backoff(uint16_t new_backoff);
	command uint16_t get_min_backoff();
	command error_t set_min_backoff(uint16_t new_min_backoff);
	command uint8_t get_ack();
	command error_t set_ack(uint8_t new_ack);
	command uint8_t get_cca();
	command error_t set_cca(uint8_t new_cca);
	command uint8_t get_crc();
	command error_t set_crc(uint8_t new_crc);
}

