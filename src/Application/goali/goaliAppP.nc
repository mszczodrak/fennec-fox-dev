/*
 *  goali application module for Fennec Fox platform.
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
 * Application: goali Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "goaliApp.h"
#include "ADXL345.h"

module goaliAppP {
provides interface Mgmt;

/* Swift Fox parameter interface */
uses interface goaliAppParams;

/* Network Interfaces */
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

/* System Interfaces */
uses interface Timer<TMilli> as Timer;
uses interface Leds;

/* Sensors interfaces */
uses interface Read<uint16_t> as TempSensor;
uses interface Read<adxl345_readxyt_t> as axis;
uses interface SplitControl as AccelControl;
}

implementation {

uint16_t temp_data = 0;
adxl345_readxyt_t accel_data;

task void report_measurements() {

	printf("Temp: %d\n", temp_data);
	printf("X [%d] Y [%d] Z [%d]\n", accel_data.x_axis, accel_data.y_axis,
					accel_data.z_axis);
	printfflush();
}

command error_t Mgmt.start() {
	dbg("Application", "goaliApp Mgmt.start()");
	call Timer.startPeriodic(call goaliAppParams.get_delay());
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("Application", "goaliApp Mgmt.start()");
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	call Leds.led2Toggle();
	call TempSensor.read();
}

event void TempSensor.readDone(error_t error, uint16_t data) {
	if (error == SUCCESS){
		temp_data = data;
		call Leds.set(0);
		call AccelControl.start();
	} else {
		call Leds.set(1);
		call TempSensor.read();
	}
}

event void AccelControl.startDone(error_t err) {
	if (err == SUCCESS) {
		call Leds.set(0);
		call axis.read();
	} else {
		call Leds.set(1);
		call AccelControl.start();
	}
}

event void AccelControl.stopDone(error_t err) {}

event void axis.readDone(error_t err, adxl345_readxyt_t data) {
	if (err == SUCCESS) {
		memcpy(&accel_data, &data, sizeof(adxl345_readxyt_t));
		//call AccelControl.stop();
		post report_measurements();
	} else {
		call axis.read();
	}
}





}
