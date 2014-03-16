
interface Fennec {
	async command state_t getStateId();
	command struct state* getStateRecord();
	command error_t setStateAndSeq(state_t state, uint16_t seq);
	command uint16_t getStateSeq();
	async command module_t getModuleId(process_t conf, layer_t layer);
	command void systemProcessId(process_t process_id);
}
