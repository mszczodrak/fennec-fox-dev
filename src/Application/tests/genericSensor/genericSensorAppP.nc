/*
 *  Generic Sensor Application module for Fennec Fox platform.
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
 * Application: Generic Sensor Application Module
 * Author: Marcin Szczodrak
 * Date: 1/2/2013
 * Last Modified: 1/2/2013
 */


#include <Fennec.h>
#include "genericSensorApp.h"

module genericSensorAppP {
provides interface Mgmt;

uses interface genericSensorAppParams ;

/* Network interfaces */
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface SensorCtrl;
uses interface SensorInfo;
uses interface AdcSetup;
uses interface Read<ff_sensor_data_t>;

uses interface Timer<TMilli> as Timer;
uses interface Leds;

}

implementation {

ff_sensor_data_t data;

task void printf_sensor_info() {
	call Leds.led1Toggle();
	printf("Sensor ID: %d\t\tSensor Type: %d\n", data.id, data.type);
	printf("Sampling Frequency: %lu\n", call genericSensorAppParams.get_freq());
	printf("Measurement Size: %d\n", data.size);
	printf("Sequence: %lu\n", data.seq);
	printf("Raw measurement: %d\n", *(uint16_t*)data.raw);
	printf("Calibrated measurement: %d\n\n", *(uint16_t*)data.calibrated);
	printfflush();
}

command error_t Mgmt.start() {
	call Timer.startPeriodic(call genericSensorAppParams.get_freq());
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Read.readDone(error_t error, ff_sensor_data_t new_data) {
	if (error == SUCCESS) {
		call Leds.led2Toggle();
		memcpy(&data, &new_data, sizeof(ff_sensor_data_t));
		post printf_sensor_info();
	} else {
		call Leds.led0On();
	}
}

event void Timer.fired() {
	if (call Read.read() != SUCCESS) {
		call Leds.led0On();
	}
}

}
