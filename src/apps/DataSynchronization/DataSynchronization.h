#ifndef DATA_SYNCHRONIZATION_APP_H
#define DATA_SYNCHRONIZATION_APP_H

#include <Fennec.h>

nx_struct fennec_network_data {
	nx_uint16_t sequence;
	nx_uint8_t history[VARIABLE_HISTORY];
	nx_struct global_data_msg data;
	nx_uint16_t crc;
};

#endif
