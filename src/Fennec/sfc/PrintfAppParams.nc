interface PrintfAppParams {
	event void receive_status(uint16_t status_flag);
	command void send_status(uint16_t status_flag);
}

