interface FennecState {
	command state_t getStateId();
	command uint16_t getStateSeq();
	command error_t setStateAndSeq(state_t state, uint16_t seq);
	command void resendDone(error_t error);
	event void resend();
}
