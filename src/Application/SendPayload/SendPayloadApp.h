#ifndef _SEND_PAYLOAD_H
#define _SEND_PAYLOAD_H

#define EXTRA_SIZE 100

nx_struct payload_msg {
   nx_uint16_t counter;
   nx_uint8_t payload[EXTRA_SIZE];
};

#endif

