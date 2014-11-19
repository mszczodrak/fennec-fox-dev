#ifndef BEDS_APP_H
#define BEDS_APP_H

#include <Fennec.h>

#define DATA_MAX_PAYLOAD	50
#define MAX_HIST_VARS   	20

#define BEDS_WRAPPER		122
#define BEDS_RANDOM_INCREASE	10

nx_struct BEDS_data {
	nx_uint16_t data_crc;
	nx_uint8_t sequence;
	nx_uint8_t data[DATA_MAX_PAYLOAD];
	nx_uint8_t var_hist[MAX_HIST_VARS];
	nx_uint16_t packet_crc;
};

#endif
