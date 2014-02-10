#ifndef SIM_IO_H
#define SIM_IO_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void sim_io_init();
int sim_read_io(uint16_t node_id);
int sim_write_io(uint16_t node_id, uint32_t val);

int sim_add_read_io(uint16_t node_id, uint8_t size);
int sim_add_write_io(uint16_t node_id, uint8_t size);
#ifdef __cplusplus
}
#endif


#endif // SIM_IO_H
