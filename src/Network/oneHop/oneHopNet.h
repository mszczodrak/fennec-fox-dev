#ifndef __ONEHOP_NET_H_
#define __ONEHOP_NET_H_

/*
  OneHop Network header
  
  +--------+--------+--------------------+---------------+
  |  flags |  seq   |  destination_addr  |  source_addr  |
  +--------+--------+--------------------+---------------+

*/

nx_struct oneHop_net_header {
  nxle_uint8_t flags;
  nxle_uint8_t seq;
/*  nxle_uint16_t dest;  
  nxle_uint16_t src;
  nxle_uint8_t (COUNT(0) payload)[0]; */
};

#endif
