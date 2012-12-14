#ifndef __MESSAGE_H__
#define __MESSAGE_H__

//#include "platform_message.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 127
#endif

#ifndef TOS_BCAST_ADDR
#define TOS_BCAST_ADDR 0xFFFF
#endif


#include <Serial.h>

typedef union message_header {
  cc2420_header_t cc2420;
  serial_header_t serial;
} message_header_t;

typedef union TOSRadioFooter {
  cc2420_footer_t cc2420;
} message_footer_t;




typedef nx_struct metadata_t {
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t tx_power;
#ifndef TOSSIM
  nx_bool crc;
  nx_bool ack;
  nx_bool timesync;
#else
  nx_uint8_t crc;
  nx_uint8_t ack;
  nx_uint8_t timesync;
#endif
  nx_uint32_t timestamp;
  nx_uint16_t rxInterval;
  nx_uint16_t maxRetries;
  nx_uint16_t retryDelay;
} metadata_t;


/*
typedef union TOSRadioMetadata {
  metadata_t cc2420;
  serial_metadata_t serial;
} message_metadata_t;
*/

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

#endif
