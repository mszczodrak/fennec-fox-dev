#ifndef DATA_SYNCHRONIZATION_APP_H
#define DATA_SYNCHRONIZATION_APP_H

#include <Fennec.h>

#define DATA_SYNC_MAX_PAYLOAD	80
#define DATA_DUMP_MAX_PAYLOAD + VARIABLE_HISTORY

nx_struct fennec_network_data {
	nx_uint16_t dump_offset;
	nx_uint16_t sequence;
	nx_uint8_t data_len;
	nx_uint8_t data[DATA_SYNC_MAX_PAYLOAD];
	nx_uint8_t history[VARIABLE_HISTORY];
};

#endif
