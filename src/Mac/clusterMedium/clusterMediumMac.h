#ifndef __CLUSTER_MEDIUM_MAC_H__
#define __CLUSTER_MEDIUM_MAC_H__

nx_struct cluster_medium_mac_header {
  /* nx_struct fennec_header fennec; */
  nxle_uint8_t cluster_id;
  /* nx_uint16_t dest; */
  /* nx_uint16_t src; */
};

enum {
  CLUSTER_MEDIUM_SAMPLE_DELAY = 1,

  CLUSTER_MEDIUM_SEND_ATTEMPTS = 3,

};


#endif
