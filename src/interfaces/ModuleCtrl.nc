interface ModuleCtrl {
	command error_t start(uint8_t module_id);
	command error_t stop(uint8_t module_id);
	event void startDone(uint8_t module_id, error_t error);
	event void stopDone(uint8_t module_id, error_t error);
}
