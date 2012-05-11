#ifndef _GOALI_DISTRIBUTED_JACOBI_H
#define _GOALI_DISTRIBUTED_JACOBI_H

nx_struct goali_distributed_jacobi_msg {
   nx_uint16_t counter;
   nx_uint16_t node_id;
   nx_uint16_t value;
};

#endif

