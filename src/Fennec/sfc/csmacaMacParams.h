#ifndef _FF_MODULE_csmacaMac_H_
#define _FF_MODULE_csmacaMac_H_

struct csmacaMac_params {
	uint16_t sink_addr;
	uint16_t delay_after_receive;
	uint16_t backoff;
	uint16_t min_backoff;
	uint8_t ack;
	uint8_t cca;
	uint8_t crc;
};

struct csmacaMac_params csmacaMac_data;
#endif
