interface Serial {
	command error_t send(uint8_t *start_buf, uint32_t total_size);
	event void sendDone(error_t success);
}
