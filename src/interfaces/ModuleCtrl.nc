#include <Fennec.h>

interface ModuleCtrl {
	command error_t start(module_t module_id);
	command error_t stop(module_t module_id);
	event void startDone(error_t error);
	event void stopDone(error_t error);
}
