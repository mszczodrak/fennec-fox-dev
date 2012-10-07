#ifndef _FF_MODULE_tdmaMac_H_
#define _FF_MODULE_tdmaMac_H_

struct tdmaMac_params {
	uint16_t root_addr;
	uint16_t frame_size;
	uint16_t node_time;
	uint16_t radio_off_time;
	uint16_t backoff;
	uint16_t min_backoff;
	uint8_t ack;
	uint8_t cca;
	uint8_t crc;
};

struct tdmaMac_params tdmaMac_data;
#endif
