#ifndef _FF_MODULE_csmacaRadio_H_
#define _FF_MODULE_csmacaRadio_H_

struct csmacaRadio_params {
	uint16_t sink_addr;
	uint8_t channel;
	uint8_t power;
	uint16_t remote_wakeup;
	uint16_t delay_after_receive;
	uint16_t backoff;
	uint16_t min_backoff;
	uint8_t ack;
	uint8_t cca;
	uint8_t crc;
};

struct csmacaRadio_params csmacaRadio_data;
#endif
