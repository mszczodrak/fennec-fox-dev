interface CounterAppParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint16_t get_delay();
	command error_t set_delay(uint16_t new_delay);
	command uint16_t get_delay_scale();
	command error_t set_delay_scale(uint16_t new_delay_scale);
	command uint16_t get_src();
	command error_t set_src(uint16_t new_src);
	command uint16_t get_dest();
	command error_t set_dest(uint16_t new_dest);
}

