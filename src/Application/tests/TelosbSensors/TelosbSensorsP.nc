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

uses interface Read<uint16_t> ReadHumidity;
uses interface Read<uint16_t> ReadTemperature
uses interface Read<uint16_t> ReadLight;

uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint16_t hum;
uint16_t temp;
uint16_t light;

task void report_measurements() {
	dbgs(F_APPLICATION, S_NONE, hum, temp, light);
}

command error_t SplitControl.start() {
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
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

void Timer.fired() {
	call ReadHumidity.read();
}

event void ReadHumidity.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadHumidity.readDone(%u %u)",
                                                        error, val);
	hum = val;
	call ReadTemperature.read();
}

event void ReadTemperature.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadTemperature.readDone(%u %u)",
                                                        error, val);
	temp = val;
	call ReadLight.read();
}

event void ReadLight.readDone(error_t error, uint16_t val) {
        dbg("Application", "Application TelosbSensors ReadLight.readDone(%u %u)",
                                                        error, val);
	light = val;
	post report_measurements();
}
}
