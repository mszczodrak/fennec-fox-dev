#ifndef BEDS_APP_H
#define BEDS_APP_H

#include <Fennec.h>

#define DATA_MAX_PAYLOAD	80

nx_struct fennec_network_data {
	nx_uint16_t crc;
	nx_uint16_t sequence;
	nx_uint8_t data[DATA_MAX_PAYLOAD];
};

#endif
