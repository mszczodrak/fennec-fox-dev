#ifndef _PHIDGET_1133_0_DRIVER_H_
#define _PHIDGET_1133_0_DRIVER_H_

#include "Msp430Adc12.h"

#define PHIDGET_1133_0_DEFAULT_SENSITIVITY 	10
#define PHIDGET_1133_0_DEFAULT_RATE 		256
#define PHIDGET_1133_0_DEFAULT_SIGNALING 	0

#define PHIDGET_1133_0_SENSOR_NO_SOUND 		0
#define PHIDGET_1133_0_SENSOR_SOUND_STEP 	10
#define PHIDGET_1133_0_SENSOR_SOUND_HIST 	2

msp430adc12_channel_config_t phidget_1133_0_adc_config = {
    INPUT_CHANNEL_A7,           // input channel
    REFERENCE_AVcc_AVss,        // reference voltage
    REFVOLT_LEVEL_NONE,         // reference voltage level
    SHT_SOURCE_ACLK,            // clock source sample-hold-time
    SHT_CLOCK_DIV_1,            // clock divider sample-hold-time
    SAMPLE_HOLD_4_CYCLES,       // sample-hold-time
    SAMPCON_SOURCE_SMCLK,       // clock source sampcon signal
    SAMPCON_CLOCK_DIV_1         // clock divider sampcon
};

#endif
