#ifndef __IDEP_NET_H_
#define __IDEP_NET_H_

enum {
  IDEP_RANDOM_DELAY_PERIOD = 70,
  IDEP_MIN_DELAY_PERIOD = 5,
  IDEP_RECEIVE_DELAY = 100,
  IDEP_MAX_OPERATION_TIME = 400,
  IDEP_MAX_OWN_TRANSMISSION_DELAY = 400,
  IDEP_HARD_LIMIT = 400,
  IDEP_DELAY_INCREASE = 5,
  IDEP_MINIMUM_DELAY_AHEAD = 1,
  IDEP_MISSING_IMPACT = 35,
  IDEP_SEND_DONE_DELAY_INCREASE = 20,
};

nx_struct idep_header {
  nxle_uint8_t flags;
  nxle_uint8_t seq;
  nxle_uint8_t len;
  nxle_uint8_t counter;
};

#endif
