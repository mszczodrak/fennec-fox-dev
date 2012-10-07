interface BlinkAppParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint8_t get_led();
	command error_t set_led(uint8_t new_led);
	command uint16_t get_delay();
	command error_t set_delay(uint16_t new_delay);
}

