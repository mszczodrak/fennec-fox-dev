#ifndef __SIMPLEPRELOADACKOK_MAC_H__
#define __SIMPLEPRELOADACKOK_MAC_H__

typedef nx_struct simplePreloadAckOk_mac_header_t {
  nxle_uint8_t length;
  nxle_uint8_t conf;
  nxle_uint16_t dest;
  nxle_uint16_t src;
} simplePreloadAckOk_mac_header_t;

enum {
  // size of the header not including the length byte
  SIMPLEPRELOADACKOK_MAC_HEADER_SIZE = sizeof( simplePreloadAckOk_mac_header_t ),
  // size of the footer (FCS field)
  SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE = sizeof( uint16_t ),

  SIMPLEPRELOADACKOK_ACK_TIME = 100,
  SIMPLEPRELOADACKOK_OK_TIME = 20,
};

typedef nx_struct simplePreloadAckOk_mac_footer_t {
  nx_uint16_t footer;
} simplePreloadAckOk_mac_footer_t;

enum {
  READY = 1,
  FIRST_LOADING = 2,
  FIRST_SENDING = 3,
  FIRST_RESENDING = 11,
  SEND_DONE = 4,
  WAITING_ACK = 5,
  RESENDING_LAST = 8,
  STOPPED = 9,
  OK_LOADING = 12,
  OK_LOADED = 13,
  OK_SENDING = 14,
  WAITING_OK = 15,
  RECEIVED_ACK = 16,
  ACK_LOADING = 17,
  ACK_LOADED = 18,
};

#endif
