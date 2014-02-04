/*
 * Copyright (c) 2009, Columbia University.
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
  * Virtual Phidget Adc sensor used in cape simulator
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/08/2014
  */

#include <Fennec.h>
#define VIRTUAL_ADC_VALUE	5

generic module CapeAdcSensorP() {
provides interface SensorInfo;
provides interface SensorCtrl;
provides interface Read<ff_sensor_data_t> as Read;
provides interface AdcSetup;
uses interface Timer<TMilli> as Timer;   
uses interface Timer<TMilli> as TimerSensor;
}

implementation {

norace uint16_t raw_data = 0;
norace uint16_t battery = 0;
norace bool busy = FALSE;
norace uint32_t sequence = 0;

uint32_t rate;

ff_sensor_data_t return_data;

uint8_t adc_channel = 255;


task void readDone() {
	signal Read.readDone(SUCCESS, return_data);
}

task void getMeasurement() {
	dbg("Sensor", "CapeAdcSensorP getMeasurement()");
	busy = TRUE;
	call TimerSensor.startOneShot(100);
}

task void data_ready() {
	/* calibrated */
	dbg("Sensor", "CapeAdcSensorP data_ready()");

        return_data.size = sizeof(raw_data);
        return_data.seq = ++sequence;
        return_data.raw = &raw_data;
        return_data.calibrated = &raw_data;
        return_data.type = call SensorInfo.getType();
        return_data.id = call SensorInfo.getId();
        post readDone();
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_UNKNOWN;
}

command sensor_id_t SensorInfo.getId() {
        return FS_GENERIC;
}

command error_t SensorCtrl.setRate(uint32_t new_rate) {
	rate = new_rate;
	call Timer.startPeriodic(rate);
	return SUCCESS;
}

command uint32_t SensorCtrl.getRate() {
        return rate;
}

command error_t AdcSetup.set_input_channel(uint8_t new_input_channel) {
	dbg("Sensor", "CapeAdcSensorP AdcSetup.set_input_channel(%d) - was %d", new_input_channel, adc_channel);
        adc_channel = new_input_channel;
        return SUCCESS;
}

command uint8_t AdcSetup.get_input_channel(){
        return adc_channel;
}

command error_t Read.read() {
	dbg("Sensor", "CapeAdcSensorP Read.read()");
	if (busy == TRUE) return EBUSY;
        post getMeasurement();
        return SUCCESS;
}

event void Timer.fired() {
	if (busy == TRUE) return;
	post getMeasurement();
}

event void TimerSensor.fired() {
	raw_data = VIRTUAL_ADC_VALUE * (1 + adc_channel);
	busy = FALSE;
	post data_ready();
}

default event void Read.readDone(error_t err, ff_sensor_data_t data) {}

}
