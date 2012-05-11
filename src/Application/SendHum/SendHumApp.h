#ifndef _SEND_HUM_H
#define _SEND_HUM_H

#define SEND_DELAY 2048

typedef nx_struct {
   nx_uint16_t counter;
   nx_uint16_t value;
} hum_msg_t;

#endif

