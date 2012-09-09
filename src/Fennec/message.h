#ifndef __MESSAGE_H__
#define __MESSAGE_H__

#include "platform_message.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 127
#endif

#ifndef TOS_BCAST_ADDR
#define TOS_BCAST_ADDR 0xFFFF
#endif

typedef nx_struct metadata_t {
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t tx_power;
  nx_bool crc;
  nx_bool ack;
  nx_bool timesync;
  nx_uint32_t timestamp;
  nx_uint16_t rxInterval;

  /** Packet Link Metadata */
#ifdef PACKET_LINK
  nx_uint16_t maxRetries;
  nx_uint16_t retryDelay;
#endif
} metadata_t;


typedef nx_struct message_t {
  nx_uint8_t header[sizeof(message_header_t)];
  nx_uint8_t data[TOSH_DATA_LENGTH];
  nx_uint8_t footer[sizeof(message_footer_t)];
  nx_uint8_t metadata[sizeof(metadata_t)];
  nx_uint16_t conf;
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t crc;
  nx_uint8_t ack;
  nx_uint16_t rxInterval;
} message_t;

/*
 * This resource is used to arbitrate access between ActiveMessageC,
 * Ieee154MessageC and possibly future MessageC components to the 
 * underlying radio driver.
 */
#define RADIO_SEND_RESOURCE "RADIO_SEND_RESOURCE"

#endif
