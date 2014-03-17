
interface Fennec {
	command struct state* getStateRecord();
	command module_t getModuleId(process_t conf, layer_t layer);
	command struct network_process * getPrivilegedProcesses();
	command struct network_process * getOrdinaryProcesses();
}
