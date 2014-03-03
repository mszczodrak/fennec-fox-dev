/*
 * Copyright (c) 2011, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox Z1 Sensors application driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 03/02/2014
  */


#ifndef __Z1SensorsAdc_H_
#define __Z1SensorsAdc_H_

#ifndef TOSSIM
#include "Msp430Adc12.h"

msp430adc12_channel_config_t adc_config_0 = {
	INPUT_CHANNEL_A0,           // input channel
	REFERENCE_AVcc_AVss,        // reference voltage
	REFVOLT_LEVEL_NONE,         // reference voltage level
	SHT_SOURCE_ACLK,            // clock source sample-hold-time
	SHT_CLOCK_DIV_1,            // clock divider sample-hold-time
	SAMPLE_HOLD_4_CYCLES,       // sample-hold-time
	SAMPCON_SOURCE_SMCLK,       // clock source sampcon signal
	SAMPCON_CLOCK_DIV_1         // clock divider sampcon
};

msp430adc12_channel_config_t adc_config_1 = {
	INPUT_CHANNEL_A1,           // input channel
	REFERENCE_AVcc_AVss,        // reference voltage
	REFVOLT_LEVEL_NONE,         // reference voltage level
	SHT_SOURCE_ACLK,            // clock source sample-hold-time
	SHT_CLOCK_DIV_1,            // clock divider sample-hold-time
	SAMPLE_HOLD_4_CYCLES,       // sample-hold-time
	SAMPCON_SOURCE_SMCLK,       // clock source sampcon signal
	SAMPCON_CLOCK_DIV_1         // clock divider sampcon
};

msp430adc12_channel_config_t adc_config_3 = {
	INPUT_CHANNEL_A3,           // input channel
	REFERENCE_AVcc_AVss,        // reference voltage
	REFVOLT_LEVEL_NONE,         // reference voltage level
	SHT_SOURCE_ACLK,            // clock source sample-hold-time
	SHT_CLOCK_DIV_1,            // clock divider sample-hold-time
	SAMPLE_HOLD_4_CYCLES,       // sample-hold-time
	SAMPCON_SOURCE_SMCLK,       // clock source sampcon signal
	SAMPCON_CLOCK_DIV_1         // clock divider sampcon
};

msp430adc12_channel_config_t adc_config_7 = {
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
#endif
