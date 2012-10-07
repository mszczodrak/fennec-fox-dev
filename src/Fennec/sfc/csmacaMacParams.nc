interface csmacaMacParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint16_t get_sink_addr();
	command error_t set_sink_addr(uint16_t new_sink_addr);
	command uint16_t get_delay_after_receive();
	command error_t set_delay_after_receive(uint16_t new_delay_after_receive);
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

