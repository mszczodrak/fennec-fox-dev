#ifndef SIM_IO_H
#define SIM_IO_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void sim_io_init();
double sim_read_output(uint16_t node_id, int input_id);
void sim_write_input(uint16_t node_id, double val, int input_id);

#ifdef __cplusplus
}
#endif


#endif // SIM_IO_H
