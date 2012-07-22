#ifndef _PHIDGET_1111_0_DRIVER_H_
#define _PHIDGET_1111_0_DRIVER_H_

#include "Msp430Adc12.h"

#define PHIDGET_1111_0_DEFAULT_SENSITIVITY 	10
#define PHIDGET_1111_0_DEFAULT_RATE 		256
#define PHIDGET_1111_0_DEFAULT_SIGNALING 	0

#define PHIDGET_1111_0_SENSOR_NO_MOTION 	2350
#define PHIDGET_1111_0_SENSOR_MOTION_STEP 	(2350 / 100)

#ifndef PHIDGET_1111_0_INPUT_CHANNEL
#define PHIDGET_1111_0_INPUT_CHANNEL	INPUT_CHANNEL_A1

msp430adc12_channel_config_t phidget_1111_0_adc_config = {
    PHIDGET_1111_0_INPUT_CHANNEL,           	// input channel
    REFERENCE_AVcc_AVss,        		// reference voltage
    REFVOLT_LEVEL_NONE,         		// reference voltage level
    SHT_SOURCE_ACLK,            		// clock source sample-hold-time
    SHT_CLOCK_DIV_1,            		// clock divider sample-hold-time
    SAMPLE_HOLD_4_CYCLES,       		// sample-hold-time
    SAMPCON_SOURCE_SMCLK,       		// clock source sampcon signal
    SAMPCON_CLOCK_DIV_1         		// clock divider sampcon
};

#endif
