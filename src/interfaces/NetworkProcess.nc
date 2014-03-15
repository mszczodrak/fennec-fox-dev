interface NetworkProcess {
	command error_t start(process_t process_id);
	command error_t stop(process_t process_id);
	event void startDone(error_t err);
	event void stopDone(error_t err);
}
