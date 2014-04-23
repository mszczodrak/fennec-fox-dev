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

#include <Fennec.h>
#include "Z1Sensors.h"

generic module Z1SensorsP(process_t process) {
provides interface SplitControl;

uses interface Z1SensorsParams;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

/* Serial Interfaces */
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface Receive as SerialReceive;
uses interface SplitControl as SerialSplitControl;

uses interface Read<uint16_t> as ReadTemperature;

uses interface Read<uint16_t> as ReadAdc0;
uses interface Read<uint16_t> as ReadAdc1;
uses interface Read<uint16_t> as ReadAdc3;
uses interface Read<uint16_t> as ReadAdc7;

#ifndef TOSSIM
provides interface AdcConfigure<const msp430adc12_channel_config_t*> as ReadAdc0Configure;
provides interface AdcConfigure<const msp430adc12_channel_config_t*> as ReadAdc1Configure;
provides interface AdcConfigure<const msp430adc12_channel_config_t*> as ReadAdc3Configure;
provides interface AdcConfigure<const msp430adc12_channel_config_t*> as ReadAdc7Configure;
#endif

uses interface Read<uint16_t> as ReadXaxis;  
uses interface Read<uint16_t> as ReadYaxis;  
uses interface Read<uint16_t> as ReadZaxis;  
uses interface SplitControl as AccelSplitControl;  

uses interface Read<uint16_t> as ReadBattery;

uses interface Timer<TMilli> as Timer;
uses interface Leds;

}

implementation {

/* Z1Sensors app
 * Takes two parameters:
 * uint16_t dest : the address of the mote to which the sensor
 *                      measurements should be send to
 *                      default value: 0
 * uint16_t sampling_rate : the millisecond delay between consecutive
 *                      rounds of sensors' sampling
 *                      default value: 1024
 */

norace z1_sensors_t *data = NULL;
void *serial_data = NULL;
norace message_t network_packet;
message_t serial_packet;
uint16_t dest;

task void report_measurements() {
	call Leds.led1Toggle();

	if (call SubAMSend.send(dest, &network_packet,
			sizeof(z1_sensors_t)) != SUCCESS) {
		call Leds.led0On();
		signal SubAMSend.sendDone(&network_packet, FAIL);
	}
}

task void send_serial_message() {
	call Leds.led2Toggle();
	if (call SerialAMSend.send(BROADCAST, &serial_packet, sizeof(z1_sensors_t)) != SUCCESS) {
		signal SerialAMSend.sendDone(&serial_packet, FAIL);
		call Leds.led0On();
	}
}

command error_t SplitControl.start() {
	data = (z1_sensors_t*)call SubAMSend.getPayload(&network_packet,
							sizeof(z1_sensors_t));
	data->seq = 0;
	data->src = TOS_NODE_ID;

	call SerialSplitControl.start();

#ifndef TOSSIM
	call AccelSplitControl.start();
#endif

	serial_data = (void*) call SerialAMSend.getPayload(&serial_packet,
                                                        sizeof(z1_sensors_t));
	if (call Z1SensorsParams.get_dest()) {
		dest = call Z1SensorsParams.get_dest();
	} else {
		dest = TOS_NODE_ID;
	}

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
#ifdef TOSSIM
	z1_sensors_t *d = (z1_sensors_t*)payload;
#endif

	memcpy(serial_data, payload, len);

	post send_serial_message();

	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	data->seq++;
	call ReadTemperature.read();
}

event void ReadTemperature.readDone(error_t error, uint16_t val) {
	data->temp = val;
	call ReadAdc0.read();
}

event void ReadAdc0.readDone( error_t result, uint16_t val ) {
	data->adc[0] = val;
	call ReadAdc1.read();
}

event void ReadAdc1.readDone( error_t result, uint16_t val ) {
	data->adc[1] = val;
	call ReadAdc3.read();
}

event void ReadAdc3.readDone( error_t result, uint16_t val ) {
	data->adc[2] = val;
	call ReadAdc7.read();
}

event void ReadAdc7.readDone( error_t result, uint16_t val ) {
	data->adc[3] = val;
	call ReadXaxis.read();
}

event void ReadXaxis.readDone(error_t error, uint16_t val) {
	data->accel[0] = val;
	call ReadYaxis.read();
}

event void ReadYaxis.readDone(error_t error, uint16_t val) {
	data->accel[1] = val;
	call ReadZaxis.read();
}

event void ReadZaxis.readDone(error_t error, uint16_t val) {
	data->accel[2] = val;
	call ReadBattery.read();
}

event void ReadBattery.readDone(error_t error, uint16_t val) {
	data->battery = val;
	post report_measurements();
}

#ifndef TOSSIM
async command const msp430adc12_channel_config_t* ReadAdc0Configure.getConfiguration() {
	return &adc_config_0;
}

async command const msp430adc12_channel_config_t* ReadAdc1Configure.getConfiguration() {
	return &adc_config_1;
}

async command const msp430adc12_channel_config_t* ReadAdc3Configure.getConfiguration() {
	return &adc_config_3;
}

async command const msp430adc12_channel_config_t* ReadAdc7Configure.getConfiguration() {
	return &adc_config_7;
}
#endif

event void SerialSplitControl.startDone(error_t error) {
}

event void SerialSplitControl.stopDone(error_t error) {
}

event void AccelSplitControl.startDone(error_t err) {
}

event void AccelSplitControl.stopDone(error_t err) {
}

event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SerialAMSend.sendDone(message_t *msg, error_t error) {
}


}
