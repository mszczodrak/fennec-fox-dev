#ifndef __csma_H_
#define __csma_H_

#define csma_RECEIVE_HISTORY_SIZE	4
#define csma_INVALID_ELEMENT		0xFF
#define csma_RECEIVE_QUEUE_SIZE	5
#define csma_TIMER_DELAY		300

typedef nx_struct csma_header_t {
        nxle_uint16_t fcf;
        nxle_uint8_t dsn;
        nxle_uint16_t destpan;
        nxle_uint16_t dest;
        nxle_uint16_t src;
} csma_header_t;


#endif

