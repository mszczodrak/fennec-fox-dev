
interface Fennec {
	command state_t getStateId();
	command struct state* getStateRecord();
	command error_t setStateAndSeq(state_t state, uint16_t seq);
	command uint16_t getStateSeq();
	command void eventOccured(module_t module_id, uint16_t oc);
}
