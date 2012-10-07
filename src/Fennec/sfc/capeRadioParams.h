#ifndef _FF_MODULE_capeRadio_H_
#define _FF_MODULE_capeRadio_H_

struct capeRadio_params {
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

struct capeRadio_params capeRadio_data;
#endif
