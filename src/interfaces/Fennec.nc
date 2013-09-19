
interface Fennec {
	command state_t getStateId();
	command struct state* getStateRecord();
	command error_t setStateSeq(nx_struct network_state);
	command nx_struct network_state getStateSeq();
}
