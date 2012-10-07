#ifndef _FF_MODULE_cuMac_H_
#define _FF_MODULE_cuMac_H_

struct cuMac_params {
	uint16_t backoff;
	uint16_t min_backoff;
	uint8_t ack;
	uint8_t cca;
	uint8_t crc;
};

struct cuMac_params cuMac_data;
#endif
