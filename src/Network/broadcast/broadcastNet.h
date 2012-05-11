#ifndef __BROADCAST_NET_H_
#define __BROADCAST_NET_H_

/*
  Broadcast Network header
  
  +--------+--------+--------------------+
  |  flags |  seq   |  destination_addr  |
  +--------+--------+--------------------+

*/

nx_struct broadcast_header {
  nxle_uint8_t flags;
  nxle_uint8_t seq;
/*  nxle_uint16_t address;  
  nxle_uint8_t (COUNT(0) payload)[0]; */
};

#endif
