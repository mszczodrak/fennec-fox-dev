#ifndef _SEND_VOLTAGE_H
#define _SEND_VOLTAGE_H

#define SEND_DELAY 2048

typedef nx_struct {
   nx_uint16_t counter;
   nx_uint16_t value;
} voltage_msg_t;

#endif

