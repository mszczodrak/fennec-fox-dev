#ifndef __TRICKLE_NET_H_
#define __TRICKLE_NET_H_

enum {
	TRICKLE_DATA = 0x01,
	TRICKLE_BEACON = 0x02,

	TRICKLE_MAX_SEND_DELAY = 10,
};

nx_struct trickle_net_header {
  nxle_uint16_t seq;
  nxle_uint8_t flags;
};


#endif
