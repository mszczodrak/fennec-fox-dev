/*
    Phidget ADC Driver for Fennec Fox
    Copyright (C) 2009-2012 

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Authors: Dhananjay Palshikar (dp2575@columbia.edu)
             Marcin Szczodrak  (marcin@ieee.org)

*/


#ifndef _PHIDGET_ADC_DRIVER_H_
#define _PHIDGET_ADC_DRIVER_H_

#include "Msp430Adc12.h"

#define PHIDGET_ADC_DEFAULT_SENSITIVITY 	10
#define PHIDGET_ADC_DEFAULT_RATE 		256
#define PHIDGET_ADC_DEFAULT_SIGNALING 	0

#define PHIDGET_ADC_SENSOR_NO_INPUT 		1479 // 5V 1074
#define PHIDGET_ADC_SENSOR_STEP 	2

msp430adc12_channel_config_t phidget_adc_config = {
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
