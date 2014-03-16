
interface Fennec {
	async command state_t getStateId();
	command struct state* getStateRecord();
	command error_t setStateAndSeq(state_t state, uint16_t seq);
	command uint16_t getStateSeq();
	command void eventOccured(module_t module_id, uint16_t oc);
	async command module_t getModuleId(process_t conf, layer_t layer);
	async command process_t getConfId(module_t module_id);
	async command module_t getNextModuleId(module_t from_module_id, uint8_t to_layer_id);
	command void systemProcessId(process_t process_id);
}
