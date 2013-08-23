interface ProtocolStack {
	command error_t startConf(uint16_t conf);
	command error_t stopConf(uint16_t conf);
	event void startConfDone(error_t err);
	event void stopConfDone(error_t err);
}
