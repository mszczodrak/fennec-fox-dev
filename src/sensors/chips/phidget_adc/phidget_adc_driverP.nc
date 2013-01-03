/**
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

#include <Fennec.h>
#include "phidget_adc_driver.h"

generic module phidget_adc_driverP() @safe() {
  provides interface SensorCtrl;
  provides interface SensorInfo;
  provides interface AdcSetup;
  provides interface Read<ff_sensor_data_t>;

  uses interface Msp430Adc12SingleChannel;
  uses interface Resource;
  uses interface Read<uint16_t> as Battery;
  uses interface Timer<TMilli> as Timer;
  uses interface Leds;
}

implementation {

norace uint16_t raw_data = 0;
norace uint16_t battery = 0;

uint32_t rate;

ff_sensor_data_t return_data;

task void signal_readDone() {
	return_data.size = sizeof(raw_data);
	return_data.raw = &raw_data;
	return_data.raw = &raw_data;
        return_data.type = call SensorInfo.getType();
        return_data.id = call SensorInfo.getId();
	signal Read.readDone(SUCCESS, return_data);
}

command error_t SensorCtrl.setRate(uint32_t new_rate) {
	rate = new_rate;
	call Timer.startPeriodic(rate);
	return SUCCESS;
}

command uint32_t SensorCtrl.getRate() {
	return rate;
}

command sensor_type_t SensorInfo.getType() {
	return F_SENSOR_UNKNOWN;
}

command sensor_id_t SensorInfo.getId() {
	return FS_GENERIC;
} 

command error_t AdcSetup.set_input_channel(uint8_t new_input_channel) {
	phidget_adc_config.inch = new_input_channel;  
	return SUCCESS;
}

command uint8_t AdcSetup.get_input_channel(){
	return phidget_adc_config.inch;
}

command error_t Read.read() {
	signal Timer.fired();
	return SUCCESS;
}

event void Timer.fired() {
	call Battery.read();
	call Resource.request();
	call Resource.release();
}

event void Resource.granted() {
	call Msp430Adc12SingleChannel.configureSingle(&phidget_adc_config);
	call Msp430Adc12SingleChannel.getData();
}

async event error_t Msp430Adc12SingleChannel.singleDataReady(uint16_t data) {
	uint32_t s = data;
	s *= battery;
	s /= 4096;    
	raw_data = s;
	post signal_readDone();
	return 0;
}

event void Battery.readDone(error_t error, uint16_t data){
	if (error == SUCCESS) {
		uint32_t b = data;
		b *= 3000;
		b /= 4096;
		battery = b;
	} 
}

async event uint16_t *Msp430Adc12SingleChannel.multipleDataReady(
			uint16_t *buffer, uint16_t numSamples){
	return 0;
}

default event void Read.readDone(error_t err, ff_sensor_data_t data) {}
}

