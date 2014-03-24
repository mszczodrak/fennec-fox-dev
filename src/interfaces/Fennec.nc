
interface Fennec {
	command module_t getModuleId(process_t conf, layer_t layer);
	command struct network_process ** getPrivilegedProcesses();
	command struct network_process ** getOrdinaryProcesses();
	command process_t getProcessIdFromAM(module_t am_module_id);
}
