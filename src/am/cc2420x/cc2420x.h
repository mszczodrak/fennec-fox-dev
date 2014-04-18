#ifndef __cc2420x_H_
#define __cc2420x_H_

#define cc2420x_RECEIVE_HISTORY_SIZE	4
#define cc2420x_INVALID_ELEMENT		0xFF
#define cc2420x_RECEIVE_QUEUE_SIZE	5
#define cc2420x_TIMER_DELAY		300

typedef nx_struct cc2420x_header_t {
        nxle_uint16_t fcf;
        nxle_uint8_t dsn;
        nxle_uint16_t destpan;
        nxle_uint16_t dest;
        nxle_uint16_t src;
} cc2420x_header_t;


#endif

