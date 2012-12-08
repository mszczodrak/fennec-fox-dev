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
 * Date: 12/05/2012
 */

#include <Fennec.h>
#include "TestPhidgetAdcApp.h"

module TestPhidgetAdcAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface TestPhidgetAdcAppParams ;

  /* Network interfaces */
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface SensorCtrl as Sensor_1_Ctrl;
  uses interface Read<uint16_t> as Sensor_1_Raw;
  uses interface Read<bool> as Sensor_1_Occurence;

  uses interface SensorCtrl as Sensor_2_Ctrl;
  uses interface Read<uint16_t> as Sensor_2_Raw;
  uses interface Read<bool> as Sensor_2_Occurence;
 
  /* Serial Interfaces */ 
  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds as LedsBlink;

  /* Network Queue */
  uses interface Queue<message_t*> as NetworkQueue;

  /* Serial Queue */
  uses interface Queue<message_t*> as SerialQueue;

  /* Message Pool */
  uses interface Pool<message_t> as MessagePool;

}

implementation {

  /* array of the sensors we are handling; max we can keep track 
   * of APP_MAX_NUMBER_OF_SENSORS sensors */

  app_network_internal_t sensors[APP_MAX_NUMBER_OF_SENSORS];

  void setup_sensor_record(uint8_t i) {
     if (call MessagePool.empty()) {
       return;
     }

     sensors[i].msg = call MessagePool.get();

     if (sensors[i].msg == NULL) {
       return;
     }

     sensors[i].pkt = (app_network_t*) call NetworkAMSend.getPayload(
					sensors[i].msg, sizeof(app_network_t) + 
					sensors[i].sample_count * sizeof(nx_uint16_t));

     sensors[i].pkt->num = 0;
     sensors[i].pkt->sid = 0;
     sensors[i].pkt->freq = sensors[i].freq;
  }

  command error_t Mgmt.start() {
    /* check if this node will be sending messages over the serial */
    if ((TOS_NODE_ID == call TestPhidgetAdcAppParams.get_destination()) || 
	        (NODE == call TestPhidgetAdcAppParams.get_destination())) {
      /* if serial needed, initialize it */
      call SerialSplitControl.start();
    } else {
      /* if serial not needed, fake the readiness of the serial and move on */
      signal SerialSplitControl.startDone(SUCCESS);
    }

    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void SerialSplitControl.startDone(error_t error) {
    /* initialize sensors */
    uint8_t i;

    call Sensor_1_Ctrl.set_rate(call TestPhidgetAdcAppParams.get_s1_freq());
    call Sensor_1_Ctrl.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());
    call Sensor_1_Ctrl.set_signaling(TRUE); 
    sensors[0].sample_count = call TestPhidgetAdcAppParams.get_s1_sampleCount();
    sensors[0].freq = call TestPhidgetAdcAppParams.get_s1_freq();
    sensors[0].seqno = 0;

    call Sensor_2_Ctrl.set_rate(call TestPhidgetAdcAppParams.get_s2_freq());
    call Sensor_2_Ctrl.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());
    call Sensor_2_Ctrl.set_signaling(TRUE); 
    sensors[1].sample_count = call TestPhidgetAdcAppParams.get_s2_sampleCount();
    sensors[1].freq = call TestPhidgetAdcAppParams.get_s2_freq();
    sensors[1].seqno = 0;

    for (i=0; i < APP_MAX_NUMBER_OF_SENSORS; i++) {
      setup_sensor_record(i);
    }

    call Sensor_1_Ctrl.start();
    call Sensor_2_Ctrl.start();
    signal Mgmt.startDone(SUCCESS);
  }

  void send_serial_message(message_t *msg, uint8_t len) {
    /* Check if there is a space in queue */
    if (call SerialQueue.full()) {
      /* Queue is full, give up sending the serial message */
      call MessagePool.put(msg);
      return;
    }

    /* Check for outstanding serial transmissions */
    if (call SerialQueue.empty()) {
      /* we're ready to send - add message to queue and send it */
      call SerialQueue.enqueue(msg);
      call SerialAMSend.send(AM_BROADCAST_ADDR, msg, len);
      call LedsBlink.led0Toggle(); /*red led*/
      return;
    }

    /* Just add the message to the queue and wait */
    call SerialQueue.enqueue(msg);
  }



  
  void send_network_message(uint16_t data, uint8_t id) {
    /* check if ready to send */
    if (sensors[id].msg == NULL) {
      /* something is wrong with this sensor record */
      setup_sensor_record(id);
      return;
    }
    
    sensors[id].pkt->data[ sensors[id].pkt->num++ ] = data;

    if (sensors[id].pkt->num++ != sensors[id].sample_count) {
      return;
    }

    call LedsBlink.led2Toggle();

    if (NODE == call TestPhidgetAdcAppParams.get_destination()) {
	signal NetworkReceive.receive(sensors[id].msg, 
				(void*)sensors[id].pkt, sizeof(app_network_t) + 
				(sensors[id].sample_count * sizeof(uint16_t)));
      signal NetworkAMSend.sendDone(sensors[id].msg, SUCCESS);
      return; 
    }

    if (call NetworkAMSend.send(call TestPhidgetAdcAppParams.get_destination(), 
		sensors[id].msg, sizeof(app_network_t) + 
		(sensors[id].sample_count * sizeof(uint16_t)) ) != SUCCESS) {
      /* Failed to send */
      signal NetworkAMSend.sendDone(sensors[id].msg, FAIL);
    }    
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    if(error == SUCCESS){
      msg_payload->count = 0;
    }
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    message_t *serial_message;
    app_serial_t *serial_data_payload;

    if (call MessagePool.empty()) {
      /* well, there is not more memory space ... maybe increase pool queue */
      return msg;
    }

    serial_message = call MessagePool.get();
    if (serial_message == NULL) {
      /* something went wrong.... this should never happen */
      return msg;
    }
   
    serial_data_payload = (app_serial_t*)
			call SerialAMSend.getPayload(serial_message, 
			len + sizeof(uint16_t)); /* add space for src field */
 
    /* Get the message source node ID */
    serial_data_payload->src = call NetworkAMPacket.address(); 
    
    /* Copy the message data starting from the seqno field 
     * (for app_network_t it is the beginning of the message */
    memcpy(&(serial_data_payload->seqno), payload, len);

    send_serial_message(serial_message, len);

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
