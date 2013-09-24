
interface Fennec {
	async command state_t getStateId();
	command struct state* getStateRecord();
	command error_t setStateAndSeq(state_t state, uint16_t seq);
	command uint16_t getStateSeq();
	command void eventOccured(module_t module_id, uint16_t oc);
	async command module_t getModuleId(conf_t conf, layer_t layer);
	async command conf_t getConfId(module_t module_id);
	async command module_t getNextModuleId(module_t from_module_id, uint8_t to_layer_id);
	async command struct stack_params getConfParams(module_t module_id);
	async command error_t checkPacket(message_t *msg, uint8_t len);
}
