#ifndef _FF_MODULE_CounterApp_H_
#define _FF_MODULE_CounterApp_H_

struct CounterApp_params {
	uint16_t delay;
	uint16_t delay_scale;
	uint16_t src;
	uint16_t dest;
};

struct CounterApp_params CounterApp_data;
#endif
