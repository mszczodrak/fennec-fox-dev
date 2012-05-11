#ifndef _SEND_COUNTER_H
#define _SEND_COUNTER_H

#define EXTRA_SIZE 0

typedef nx_struct {
   nx_uint16_t counter;
   nx_uint16_t from;
   nx_uint8_t value[EXTRA_SIZE];
} counter_msg_t;

#endif

