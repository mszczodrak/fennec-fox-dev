#include <Fennec.h>

module NetworkSchedulerP @safe() {

provides interface SimpleStart;

}

implementation {

uint8_t num_of_proc = 0;

command void SimpleStart.start() {
	num_of_proc = 0;

	signal SimpleStart.startDone(SUCCESS);
}



}
