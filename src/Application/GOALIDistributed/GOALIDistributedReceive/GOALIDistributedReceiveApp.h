#ifndef _GOALI_DISTRIBUTED_RECEIVE_H
#define _GOALI_DISTRIBUTED_RECEIVE_H

nx_struct goali_distributed_receive_msg {
   nx_uint16_t counter;
   nx_uint16_t node_id;
   nx_uint16_t len;
};

#endif

