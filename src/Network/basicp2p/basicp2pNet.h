#ifndef __BASICP2P_NET_H_
#define __BASICP2P_NET_H_

nx_struct basicp2p_net_header {
  nx_uint8_t flags;
  nx_uint8_t seq;
};

struct basicp2p_net_estimate {
  nx_uint8_t *addr;
  uint8_t etx;
};

enum {
  BASICP2P_NET_DISCOVERY 		= 1,
//  BASICP2P_NET_DISCOVERY_REPLY 		= 2,
  BASICP2P_NET_DATA 			= 4,
  BASICP2P_NET_ESTIMATE			= 8,
  BASICP2P_NET_MAC_RESPOND		= 400,

  BASICP2P_NET_RESEND_DELAY 		= 30,
  BASICP2P_NET_RESEND_TRIES 		= 3,
  BASICP2P_NET_NUM_OF_ESTIMATES		= 10,
  BASICP2P_NET_MAX_ESTIMATE_DELAY	= 20,
  BASICP2P_NET_MAX_ESTIMATES_ENTRIES	= 20,
  BASICP2P_NET_MAX_ETX_COST		= 32000,
};

#endif
