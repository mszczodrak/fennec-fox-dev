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
  uses interface SensorSetup as Sensor_1_Setup;
  uses interface Read<uint16_t> as Sensor_1_Raw;

  uses interface SensorCtrl as Sensor_2_Ctrl;
  uses interface SensorSetup as Sensor_2_Setup;
  uses interface Read<uint16_t> as Sensor_2_Raw;
 
  /* Serial Interfaces */ 
  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds;

  /* Network Queue */
  uses interface Queue<message_t*> as NetworkQueue;

  /* Serial Queue */
  uses interface Queue<app_serial_internal_t> as SerialQueue;

  /* Message Pool */
  uses interface Pool<message_t> as MessagePool;

}

implementation {

  /** 
   * array of the sensors we are handling; max we can keep track 
   * of APP_MAX_NUMBER_OF_SENSORS sensors 
   */
  app_network_internal_t sensors[APP_MAX_NUMBER_OF_SENSORS];

  uint8_t state = S_STOPPED;

  void clean_sensor_record(uint8_t id);
  void setup_sensor_record(uint8_t id);
  void network_msg_tx(uint8_t id);
  void save_sensor_data(uint16_t data, uint8_t id);

  task void send_serial_message();


  /**
   * starting point for this module
   */
  command error_t Mgmt.start() {
    state = S_STARTING;
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

  event void SerialSplitControl.startDone(error_t error) {
    /* initialize sensors */
    uint8_t i;

    call Sensor_1_Ctrl.set_rate(call TestPhidgetAdcAppParams.get_s1_freq());
    call Sensor_1_Ctrl.set_signaling(TRUE); 
    call Sensor_1_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());
    sensors[0].sample_count = call TestPhidgetAdcAppParams.get_s1_sampleCount();
    sensors[0].freq = call TestPhidgetAdcAppParams.get_s1_freq();
    sensors[0].seqno = 0;

    call Sensor_2_Ctrl.set_rate(call TestPhidgetAdcAppParams.get_s2_freq());
    call Sensor_2_Ctrl.set_signaling(TRUE); 
    call Sensor_2_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());
    sensors[1].sample_count = call TestPhidgetAdcAppParams.get_s2_sampleCount();
    sensors[1].freq = call TestPhidgetAdcAppParams.get_s2_freq();
    sensors[1].seqno = 0;

    for (i=0; i < APP_MAX_NUMBER_OF_SENSORS; i++) {
      setup_sensor_record(i);
    }

    if (call Sensor_1_Ctrl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
      call Leds.led0On();
      return;
    }  
    if (call Sensor_2_Ctrl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
      call Leds.led0On();
      return;
    }  

    state = S_STARTED;
    signal Mgmt.startDone(SUCCESS);
  }

  command error_t Mgmt.stop() {
    state = S_STOPPED;
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    app_data_t *s = (app_data_t*) msg;
    if(error == SUCCESS){
      clean_sensor_record(s->sid);
    } else {
      network_msg_tx(s->sid);
    }
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    message_t *serial_message;
    app_data_t *serial_data_payload; 
    app_serial_internal_t sm;

    if (call MessagePool.empty()) {
      /* well, there is not more memory space ... maybe increase pool queue */
      call Leds.led0On();
      return msg;
    }

    serial_message = call MessagePool.get();
    if (serial_message == NULL) {
      /* something went wrong.... this should never happen */
      call Leds.led0On();
      return msg;
    }
   
    serial_data_payload = (app_data_t*)
			call SerialAMSend.getPayload(serial_message, len); 
 
    /* Get the message source node ID */
    serial_data_payload->src = call NetworkAMPacket.address(); 
    
    /* Copy the message data starting from the seqno field 
     * (for app_data_t it is the beginning of the message */
    memcpy(&(serial_data_payload->seqno), payload, len);

    /* Check if there is a space in queue */
    if (call SerialQueue.full()) {
      /* Queue is full, give up sending the serial message */
      call Leds.led0On();
      call MessagePool.put(msg);
      return msg;
    }

    /* Just add the message to the queue and wait */
    sm.msg = serial_message;
    sm.len = len;
    call SerialQueue.enqueue(sm);

    post send_serial_message();

    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void SerialAMSend.sendDone(message_t *msg, error_t error) {

  }

  event void Sensor_1_Raw.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      save_sensor_data(data, 0);
    }
  }

  event void Sensor_2_Raw.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      save_sensor_data(data, 1);
    }
  }



  event void Timer.fired() {
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}
  event void SerialSplitControl.stopDone(error_t errot){}
  event void TestPhidgetAdcAppParams.receive_status(uint16_t status_flag) {}
  event void Sensor_1_Ctrl.startDone(error_t error){}
  event void Sensor_1_Ctrl.stopDone(error_t error){}
  event void Sensor_2_Ctrl.startDone(error_t error){}
  event void Sensor_2_Ctrl.stopDone(error_t error){}



  void clean_sensor_record(uint8_t id) {
     memset(sensors[id].pkt->data, 0, (sensors[id].sample_count * sizeof(uint16_t)));
     sensors[id].pkt->num = 0;
     sensors[id].pkt->sid = id;
     sensors[id].pkt->freq = sensors[id].freq;
  }


  void setup_sensor_record(uint8_t id) {
     if (call MessagePool.empty()) {
       call Leds.led0On();
       return;
     }

     sensors[id].msg = call MessagePool.get();

     if (sensors[id].msg == NULL) {
       call Leds.led0On();
       return;
     }

     sensors[id].pkt = (app_data_t*) call NetworkAMSend.getPayload(
                                        sensors[id].msg, sizeof(app_data_t) +
                                        sensors[id].sample_count * sizeof(nx_uint16_t));

     if (sensors[id].pkt == NULL) {
       call Leds.led0On();
       return;
     }

     clean_sensor_record(id);
  }


  /**
   * sends sensor message over the network
   */
  void network_msg_tx(uint8_t id) {
    if (call NetworkAMSend.send(call TestPhidgetAdcAppParams.get_destination(),
                sensors[id].msg, sizeof(app_data_t) +
                (sensors[id].sample_count * sizeof(uint16_t)) ) != SUCCESS) {
      /* Failed to send */
      signal NetworkAMSend.sendDone(sensors[id].msg, FAIL);
    }
  }


  void save_sensor_data(uint16_t data, uint8_t id) {
    /* check if message buffer is available */
    if (sensors[id].msg == NULL) {
      /* something is wrong with this sensor record */
      setup_sensor_record(id);
      return;
    }

    sensors[id].pkt->data[ sensors[id].pkt->num ] = data;

    sensors[id].pkt->num++;

    if (sensors[id].pkt->num != sensors[id].sample_count) {
      return;
    }

    call Leds.led2Toggle();

    /**
     * if the sensor samples should be send to this node
     * (meaning, this node is the gatway), signal message receive.
     */
    if (NODE == call TestPhidgetAdcAppParams.get_destination()) {
        signal NetworkReceive.receive(sensors[id].msg,
                                (void*)sensors[id].pkt, sizeof(app_data_t) +
                                (sensors[id].sample_count * sizeof(uint16_t)));
      signal NetworkAMSend.sendDone(sensors[id].msg, SUCCESS);
      return;
    }

    /**
     * send sensor samples over the network
     */
    network_msg_tx(id);
  }


  task void send_serial_message() {
    /* Check if there is anything to send */
    if (call SerialQueue.empty()) {
      return;
    }

    /* Send message */
    if (call SerialAMSend.send(AM_BROADCAST_ADDR, (call SerialQueue.head()).msg,
				(call SerialQueue.head()).len) != SUCCESS) {
      post send_serial_message();
    }
    call Leds.led1Toggle(); /*red led*/
  }


}
