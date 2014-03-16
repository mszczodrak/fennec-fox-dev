#include <Fennec.h>

interface ModuleCtrl {
	command error_t start(module_t module_id);
	command error_t stop(module_t module_id);
	event void startDone(module_t module_id, error_t error);
	event void stopDone(module_t module_id, error_t error);
}
