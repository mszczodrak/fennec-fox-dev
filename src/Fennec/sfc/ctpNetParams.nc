interface ctpNetParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
	command uint16_t get_root();
	command error_t set_root(uint16_t new_root);
}

