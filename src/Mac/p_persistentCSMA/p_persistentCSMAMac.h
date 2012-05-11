#ifndef __PPERSISTENTCSMA_MAC_H__
#define __PPERSISTENTCSMA_MAC_H__

/*
  p-persistentCSMA Mac header
  
  +----------------+--------------------+---------------+
  |  fennec_header |  destination_addr  |  source_addr  |
  +----------------+--------------------+---------------+

*/

nx_struct p_persistentCSMA_mac_header {
  /* nx_struct fennec_header fennec; */
  /* nx_uint16_t dest; */
  /* nx_uint16_t src; */
};

enum {
  PPERSISTENTCSMA_ACK_TIME = 200,

  PPERSISTENTCSMA_SAMPLE_DELAY = 1,

  PPERSISTENTCSMA_SEND_ATTEMPTS = 3,

  PPERSISTENTCSMA_P_VALUE = 1,  // This is 1 -> 0.01 and 100 for 1,   p/100
};


#endif
