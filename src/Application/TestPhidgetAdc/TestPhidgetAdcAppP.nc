/*
 *  ADC Phidget application module for Fennec Fox platform.
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
 * Application: ADC Phidget Application Module
 * Author: Marcin Szczodrak
 * Author: Dhananjay Palshikar
 * Date: 12/05/2012
 */

#include <Fennec.h>
#include "TestPhidgetAdcApp.h"

module TestPhidgetAdcAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface TestPhidgetAdcAppParams ;
  uses interface SensorCtrl;
  uses interface Read<uint16_t> as Raw;
  uses interface Read<bool> as Occurence;

  /* Network interfaces */
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
 
  /* Serial Interfaces */ 
  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds as LedsBlink;

  /* Network Queue and Pool */
  uses interface Queue<message_t*> as NetworkQueue;
  uses interface Pool<message_t> as NetworkPool;

  /* Serial Queue and Pool */
  uses interface Queue<message_t*> as SerialQueue;
  uses interface Pool<message_t> as SerialPool;

}

implementation {

  uint16_t sampleCount = SAMPLE_COUNT_DEFAULT; //samples per packet

  message_t network_buffer;
  message_t serial_buffer;

  app_data_t *msg_payload = NULL;

  command error_t Mgmt.start() {
    sampleCount = call TestPhidgetAdcAppParams.get_sampleCount();

    /* checking for overflow for packet size */
    if (sampleCount > SAMPLE_COUNT_MAX ){ 
      sampleCount =  SAMPLE_COUNT_MAX;
    }

    /* initialize serial */
    if ((TOS_NODE_ID == call TestPhidgetAdcAppParams.get_dest()) || 
	        (NODE == call TestPhidgetAdcAppParams.get_dest())) {
      call SerialSplitControl.start();
    } else {
      signal SerialSplitControl.startDone(SUCCESS);
    }

    return SUCCESS;
  }

  event void SerialSplitControl.startDone(error_t error) {
    call SensorCtrl.set_rate(call TestPhidgetAdcAppParams.get_freq());
    call SensorCtrl.set_input_channel(call TestPhidgetAdcAppParams.get_inputChannel());
    call SensorCtrl.set_signaling(TRUE); //can be taken as param from Swift
    call SensorCtrl.start();

    msg_payload = (app_data_t*)
                call NetworkAMSend.getPayload(&network_buffer, 
			sizeof(app_data_t) + (sampleCount * sizeof(uint16_t)));

    msg_payload->count = 0;
    signal Mgmt.startDone(SUCCESS);
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }
  
  void sendMessage(uint16_t data) {
    msg_payload->data[msg_payload->count++] = data;

    if (msg_payload->count != sampleCount) {
      return;
    }
    call LedsBlink.led2Toggle();

    if (NODE == call TestPhidgetAdcAppParams.get_dest()) {
      signal NetworkReceive.receive(&network_buffer, 
	(void*)msg_payload, sizeof(app_data_t) + (sampleCount * sizeof(uint16_t)));
      signal NetworkAMSend.sendDone(&network_buffer, SUCCESS);
      return; 
    }

    if (call NetworkAMSend.send(call TestPhidgetAdcAppParams.get_dest(), 
					&network_buffer, sizeof(app_data_t) + 
				(sampleCount * sizeof(uint16_t)) ) != SUCCESS) {
    }    
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    if(error == SUCCESS){
      msg_payload->count = 0;
    }
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    app_data_t *payload_data = (app_data_t*) payload;
    app_data_t *serial_msg_payload = (app_data_t*) call SerialAMSend.getPayload(&serial_buffer, len);
    memcpy(serial_msg_payload, payload_data, len);
    call SerialAMSend.send(AM_BROADCAST_ADDR, &serial_buffer, len);
    call LedsBlink.led0Toggle(); /*red led*/
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }


  event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void SerialAMSend.sendDone(message_t *msg, error_t error) {}

  event void Raw.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      sendMessage(data);
    }
  }

  event void Timer.fired() {
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}
  event void SerialSplitControl.stopDone(error_t errot){}
  event void TestPhidgetAdcAppParams.receive_status(uint16_t status_flag) {}
  event void SensorCtrl.startDone(error_t error){}
  event void SensorCtrl.stopDone(error_t error){}
  event void Occurence.readDone(error_t error, bool data){}

}
