#ifndef __FIXEDPATH_NET_H_
#define __FIXEDPATH_NET_H_

/*
  fixedPath Network header
  
  +--------+--------+--------------------+---------------+
  |  flags |  seq   |  destination_addr  |  source_addr  |
  +--------+--------+--------------------+---------------+

*/

nx_struct fixedPath_net_header {
  nxle_uint16_t src;
  nxle_uint16_t dest;  
  nxle_uint8_t (COUNT(0) payload)[0]; 
};

#endif
