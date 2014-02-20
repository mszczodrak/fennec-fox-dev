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
  * Fennec Fox empty application driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 02/04/2014
  */


#include <Fennec.h>
#include "TelosbSensors.h"

generic module TelosbSensorsP() {
provides interface SplitControl;

uses interface TelosbSensorsParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

/* Serial Interfaces */
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface Receive as SerialReceive;
uses interface SplitControl as SerialSplitControl;

uses interface Read<uint16_t> as ReadHumidity;
uses interface Read<uint16_t> as ReadTemperature;
uses interface Read<uint16_t> as ReadLight;

uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

telosb_sensors_t *data = NULL;
message_t packet;
uint16_t dest;

task void report_measurements() {
	call Leds.led1Toggle();
	dbgs(F_APPLICATION, S_NONE, data->hum, data->temp, data->light);

	if (call NetworkAMSend.send(dest, &packet,
			sizeof(telosb_sensors_t)) != SUCCESS) {
		signal NetworkAMSend.sendDone(&packet, FAIL);
	}
}

command error_t SplitControl.start() {
	data = (telosb_sensors_t*)call NetworkAMSend.getPayload(&packet, sizeof(telosb_sensors_t));
	data->seq = 0;
	data->src = TOS_NODE_ID;
	if (call TelosbSensorsParams.get_dest()) {
		dest = call TelosbSensorsParams.get_dest();
	} else {
		dest = TOS_NODE_ID;
	}
	dbg("Application", "TelosbSensors SplitControl.start()");
	call Timer.startPeriodic(call TelosbSensorsParams.get_sampling_rate());
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Application", "TelosbSensors SplitControl.start()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	telosb_sensors_t *d = (telosb_sensors_t*)payload;
	dbg("Application", "TelosbSensors Humidity: %d, Temperature: %d, Light: %d",
					d->hum, d->temp, d->light);
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	call ReadHumidity.read();
}

event void ReadHumidity.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadHumidity.readDone(%d %d)",
                                                        error, val);
	data->hum = val;
	call ReadTemperature.read();
}

event void ReadTemperature.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadTemperature.readDone(%d %d)",
                                                        error, val);
	data->temp = val;
	call ReadLight.read();
}

event void ReadLight.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadLight.readDone(%d %d)",
                                                        error, val);
	data->light = val;
	post report_measurements();
}

event void SerialSplitControl.startDone(error_t error) {
}

event void SerialSplitControl.stopDone(error_t error) {
}

event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
}

event void SerialAMSend.sendDone(message_t *msg, error_t error) {
//        call SerialQueue.dequeue();
//        busy_serial = FALSE;
//        post send_serial_message();
}

}
