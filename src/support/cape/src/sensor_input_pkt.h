#ifndef SENSOR_INPUT_PKT_H
#define SENSOR_INPUT_PKT_H

#include <stdint.h>

struct sensor_input_pkt {
	uint16_t node_id;	/* Mote address ID */
	uint16_t sensor_id;	/* Sensor number on mote with address node_id */
	uint32_t value;		/* Sensor measurement value */
};

#endif

