#ifndef _FF_MODULE_cc2420Radio_H_
#define _FF_MODULE_cc2420Radio_H_

struct cc2420Radio_params {
	uint8_t channel;
	uint8_t power;
	uint8_t ack;
	uint8_t crc;
};

struct cc2420Radio_params cc2420Radio_data;
#endif
