#ifndef TEST_NETWORK_H
#define TEST_NETWORK_H

#include <AM.h>

enum {
 AM_TESTNETWORKMSG = 0x05,
 SAMPLE_RATE_KEY = 0x1,
 CL_TEST = 0xee,
 TEST_NETWORK_QUEUE_SIZE = 8,
};


typedef nx_struct TestNetworkMsg {
  nx_am_addr_t source;
  nx_uint16_t seqno;
} TestNetworkMsg;

#endif
