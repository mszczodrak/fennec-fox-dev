/*
 *  Phidget 1142 driver.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * Application: Phidget 1142 driver
 * Author: Marcin Szczodrak
 * Date: 12/28/2010
 * Last Modified: 1/3/2013
 */

#include <Fennec.h>
#include "phidget_1142_0_driver.h"

module phidget_1142_0_driverP @safe() {
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

uint16_t calibrated_data[PHIDGET_1142_0_SENSOR_HIST_LEN] = {0};
uint8_t index = 0;
ff_sensor_data_t return_data;
norace error_t status = SUCCESS;
norace uint32_t sequence = 0;
uint32_t freq = 0;

norace bool adc_channel_set = FALSE;

enum {
        NUM_CLIENTS = uniqueCount(UQ_PHIDGET_1142)
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

	printf("new freq %d\n", freq);

        if (freq) {
                call Timer.startPeriodic(freq);
        } else {
                call Timer.stop();
        }
};

task void readDone() {
        uint8_t i;

	printf("read done\n");
	printfflush();

        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].read) {
			printf("clieat got read\n");
			clients[i].read = 0;
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
			printf("clieat got report\n");
                        signal Read.readDone[i](status, return_data);
                }
        }
}

task void getMeasurement() {
        //call Battery.read();

	call Timer.getNow();

        if (call AdcSensorRead.read() == FAIL) {
                status = FAIL;
                post readDone();
        }
}


command error_t SensorCtrl.setRate[uint8_t id](uint32_t newRate) {
	if (adc_channel_set == FALSE) {
		call SubAdcSetup.set_input_channel(PHIDGET_1142_0_DEFAULT_ADC_CHANNEL);
		adc_channel_set = TRUE;
	}
        clients[id].read = 0;
        clients[id].rate = newRate;
        post new_freq();
        return SUCCESS;
}

command uint32_t SensorCtrl.getRate[uint8_t id]() {
	return clients[id].rate;
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_LIGHT;
}

command sensor_id_t SensorInfo.getId() {
        return FS_PHIDGET_1142_0;
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
		call SubAdcSetup.set_input_channel(PHIDGET_1142_0_DEFAULT_ADC_CHANNEL);
		adc_channel_set = TRUE;
	}
        clients[id].read = 1;
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

	/* No calibration for phidget_1142_0 */
	index++;
	index %= PHIDGET_1142_0_SENSOR_HIST_LEN;
	memcpy(&calibrated_data[index], data.raw, sizeof(data.size));

	return_data.size = data.size;
	return_data.seq = ++sequence;
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

