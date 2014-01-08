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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
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
provides interface SensorCtrl[uint8_t id];
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];
provides interface AdcSetup;
uses interface Timer<TMilli> as Timer;   
uses interface Timer<TMilli> as TimerSensor;
}

implementation {

uint16_t temp;
uint8_t pointer;
uint8_t temperaturebuff[2];
uint16_t tmpaddr;

norace uint8_t negative_number;
norace uint8_t mode;  /* Mode   * 0 -> 12-bit format 	 * 1 -> 13-bit format  */

norace uint16_t battery = 0;

norace uint16_t raw_data;
uint16_t calibrated_data;
ff_sensor_data_t return_data;
norace error_t status = SUCCESS;
norace uint32_t sequence = 0;
uint32_t freq = 0;
norace bool busy = FALSE;
uint8_t adc_channel = 0;

enum {
        NUM_CLIENTS = uniqueCount(UQ_TMP102)
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

task void start_sensor_timer() {
}

task void getMeasurement() {
	call TimerSensor.startOneShot(100);
	busy = TRUE;
}

task void data_ready() {
	/* calibrated */
	calibrated_data = raw_data * 0.0625;

        return_data.size = sizeof(uint16_t);
        return_data.seq = ++sequence;
        return_data.raw = &raw_data;
        return_data.calibrated = &calibrated_data;
        return_data.type = call SensorInfo.getType();
        return_data.id = call SensorInfo.getId();
        status = SUCCESS;
        post readDone();
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_TEMPERATURE;
}

command sensor_id_t SensorInfo.getId() {
        return FS_TI_TMP102;
}

command error_t SensorCtrl.setRate[uint8_t id](uint32_t newRate) {
        clients[id].read = 0;
        clients[id].rate = newRate;
        post new_freq();

        return SUCCESS;
}

command uint32_t SensorCtrl.getRate[uint8_t id]() {
        return clients[id].rate;
}

command error_t AdcSetup.set_input_channel(uint8_t new_input_channel) {
        adc_channel = new_input_channel;
        return SUCCESS;
}

command uint8_t AdcSetup.get_input_channel(){
        return adc_channel;
}

command error_t Read.read[uint8_t id]() {
	if (busy == TRUE) return EBUSY;
        clients[id].read = 1;
        post getMeasurement();
        return SUCCESS;
}

event void Timer.fired() {
	if (busy == TRUE) return;
	post getMeasurement();
}

event void TimerSensor.fired() {
	raw_data = VIRTUAL_ADC_VALUE * (1 + adc_channel);
	post data_ready();
}

default event void Read.readDone[uint8_t id](error_t err, ff_sensor_data_t data) {}

}
