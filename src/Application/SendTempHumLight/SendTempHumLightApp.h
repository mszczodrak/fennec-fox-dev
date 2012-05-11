#ifndef _SEND_TEMP_HUM_LIGHT_H
#define _SEND_TEMP_HUM_LIGHT_H

typedef nx_struct {
   nx_uint16_t node;
   nx_uint16_t counter;
   nx_uint16_t temp;
   nx_uint16_t hum;
   nx_uint16_t light;
} env_msg_t;

#endif

