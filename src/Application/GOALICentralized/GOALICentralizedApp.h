#ifndef _GOALI_CENTRALIZED_H
#define _GOALI_CENTRALIZED_H

typedef nx_struct goali_centralized_msg {
   nx_uint16_t counter;
   nx_uint16_t node_id;
   nx_uint16_t value;
} goali_centralized_msg_t;

enum {
  AM_GOALI_CENTRALIZED_MSG = 0x89,
  GOALI_CENTRALIZED_RESEND_DELAY = 100,
};


#endif

