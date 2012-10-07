#ifndef _FF_MODULE_smartcity001App_H_
#define _FF_MODULE_smartcity001App_H_

struct smartcity001App_params {
	uint16_t delay_ms;
	uint16_t delay_scale;
	uint16_t src;
	uint16_t dest;
	uint8_t sensor;
};

struct smartcity001App_params smartcity001App_data;
#endif
