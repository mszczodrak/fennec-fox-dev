/*
 *  Phidget 1111 driver.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Application: Phidget 1111 driver
 * Author: Marcin Szczodrak
 * Date: 12/28/2012
 * Last Modified: 12/28/2012
 */

#include <Fennec.h>
#include "phidget_1111_0_driver.h"

module phidget_1111_0_driverP @safe() {
provides interface AdcSetup;
provides interface SensorCtrl[uint8_t client_id];
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t> as Read[uint8_t client_id];

uses interface SensorCtrl as AdcSensorCtrl;
uses interface AdcSetup as SubAdcSetup;
uses interface Read<ff_sensor_data_t> as AdcSensorRead;

uses interface Timer<TMilli> as Timer;
}

implementation {

uint16_t calibrated_data[PHIDGET_1111_0_SENSOR_HIST_LEN] = {0};
uint8_t index = 0;
ff_sensor_data_t return_data;
norace error_t status = SUCCESS;
norace uint32_t sequence = 0;
uint32_t freq = 0;

norace bool adc_channel_set = FALSE;

enum {
        NUM_CLIENTS = uniqueCount(UQ_PHIDGET_1111)
};

ff_sensor_client_t clients[NUM_CLIENTS];

task void new_freq() {
        uint8_t i;
        freq = 0;
        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].rate == 0) {
                        continue;
                }

                if (freq == 0) {
                        freq = clients[i].rate;
                        continue;
                }

                freq = gcdr(freq, clients[i].rate);
        }
        if (freq) {
                call Timer.startPeriodic(freq);
        } else {
                call Timer.stop();
        }
};

task void readDone() {
        uint8_t i;

        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].read) {
                        signal Read.readDone[i](status, return_data);
                }
        }

        if (freq == 0) {
                return;
        }

        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].rate == 0) {
                        continue;
                }

                if (sequence % (clients[i].rate / freq) == 0) {
                        signal Read.readDone[i](status, return_data);
                }
        }
}

task void getMeasurement() {
        //call Battery.read();

        if (call AdcSensorRead.read() == FAIL) {
                status = FAIL;
                post readDone();
        }
}


command error_t SensorCtrl.setRate[uint8_t id](uint32_t new_rate) {
	if (adc_channel_set == FALSE) {
		call SubAdcSetup.set_input_channel(PHIDGET_1111_0_DEFAULT_ADC_CHANNEL);
	}
	return call AdcSensorCtrl.setRate(new_rate);
}

command uint32_t SensorCtrl.getRate[uint8_t id]() {
	return call AdcSensorCtrl.getRate();
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_MOTION;
}

command sensor_id_t SensorInfo.getId() {
        return FS_PHIDGET_1111_0;
}

command uint8_t AdcSetup.get_input_channel() {
	return call SubAdcSetup.get_input_channel();
}

command error_t AdcSetup.set_input_channel(uint8_t new_channel) {
	adc_channel_set = TRUE;
	return call SubAdcSetup.set_input_channel(new_channel);
}

command error_t Read.read[uint8_t id]() {
	if (adc_channel_set == FALSE) {
		call SubAdcSetup.set_input_channel(PHIDGET_1111_0_DEFAULT_ADC_CHANNEL);
	}
	post getMeasurement();
	return SUCCESS;
}

event void Timer.fired() {
	post getMeasurement();
}

event void AdcSensorRead.readDone(error_t error, ff_sensor_data_t data) {
	if (error != SUCCESS) {
		status = error;
		post readDone();
		return;
	}		

	/* No calibration for phidget_1111_0 */
	index++;
	index %= PHIDGET_1111_0_SENSOR_HIST_LEN;
	memcpy(&calibrated_data[index], data.raw, sizeof(data.size));

	return_data.size = data.size;
	return_data.raw = data.raw;
	/* apply calibrate function */
	return_data.calibrated = data.calibrated;
        return_data.type = call SensorInfo.getType();
        return_data.id = call SensorInfo.getId();
        status = SUCCESS;
        post readDone();
}


default event void Read.readDone[uint8_t id](error_t err, ff_sensor_data_t data) {}
}

