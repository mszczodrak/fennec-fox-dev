#ifndef SIM_IO_H
#define SIM_IO_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void sim_io_init();
double sim_read_output(uint16_t node_id, int input_id);
void sim_write_input(uint16_t node_id, double val, int input_id);

//int sim_add_read_io(uint16_t node_id, uint8_t size, int (*op) (int, int));
//int sim_add_write_io(uint16_t node_id, uint8_t size, int (*op) (int, int, int));

#ifdef __cplusplus
}
#endif


#endif // SIM_IO_H
