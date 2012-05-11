#ifndef _SENSE_ENVIRONMENT_H
#define _SENSE_ENVIRONMENT_H

nx_struct env_msg {
   nx_uint16_t node_id;
   nx_uint16_t counter;
   nx_uint16_t temp;
   nx_uint16_t hum;
   nx_uint16_t light;
};

enum {
  AM_ENV_MSG = 0x89,
  GOALI_CENTRALIZED_RESEND_DELAY = 100,
};


#endif

