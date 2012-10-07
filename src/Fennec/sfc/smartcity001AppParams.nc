interface smartcity001AppParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint16_t get_delay_ms();
	command error_t set_delay_ms(uint16_t new_delay_ms);
	command uint16_t get_delay_scale();
	command error_t set_delay_scale(uint16_t new_delay_scale);
	command uint16_t get_src();
	command error_t set_src(uint16_t new_src);
	command uint16_t get_dest();
	command error_t set_dest(uint16_t new_dest);
	command uint8_t get_sensor();
	command error_t set_sensor(uint8_t new_sensor);
}

