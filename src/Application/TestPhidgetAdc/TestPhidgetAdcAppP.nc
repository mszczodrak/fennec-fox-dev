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

  uses interface SensorCtrl as Sensor_0_Ctrl;
  uses interface SensorSetup as Sensor_0_Setup;
  uses interface Read<uint16_t> as Sensor_0_Raw;

  uses interface SensorCtrl as Sensor_1_Ctrl;
  uses interface SensorSetup as Sensor_1_Setup;
  uses interface Read<uint16_t> as Sensor_1_Raw;
 
  /* Serial Interfaces */ 
  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds;

  /* Network Queue */
  uses interface Queue<msg_queue_t> as NetworkQueue;

  /* Serial Queue */
  uses interface Queue<msg_queue_t> as SerialQueue;

  /* Message Pool */
  uses interface Pool<message_t> as MessagePool;

}

implementation {

  /** 
   * array of the sensors we are handling; max we can keep track 
   * of APP_MAX_NUMBER_OF_SENSORS sensors 
   */
  app_network_internal_t sensors[APP_MAX_NUMBER_OF_SENSORS];

  void clean_sensor_record(uint8_t id);
  void save_sensor_data(uint16_t data, uint8_t id);

  task void send_serial_message();
  task void send_network_message();
  task void setup_app();

  bool busy_serial;

  /**
   * starting point for this module
   */
  command error_t Mgmt.start() {
    busy_serial = FALSE;
    /* check if this node will be sending messages over the serial */
    if ((TOS_NODE_ID == call TestPhidgetAdcAppParams.get_destination()) || 
	        (NODE == call TestPhidgetAdcAppParams.get_destination())) {
      /* if serial needed, initialize it */
      call SerialSplitControl.start();
    }

    post setup_app();

    return SUCCESS;
  }


  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    /* we do not check for error, if failed to send a message, we drop
     * that message anyway
     */
    msg_queue_t nm = call NetworkQueue.dequeue();
    call MessagePool.put(nm.msg);
    nm.msg = NULL;
    nm.len = 0;
    nm.addr = 0;

    post send_network_message();
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    message_t *serial_message;
    app_data_t *serial_data_payload; 
    msg_queue_t sm;

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
 
    /* Copy the message data starting from the seqno field 
     * (for app_data_t it is the beginning of the message */
    memcpy(serial_data_payload, payload, len);

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
    sm.addr = AM_BROADCAST_ADDR; 
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
    msg_queue_t sm = call SerialQueue.dequeue();
    call MessagePool.put(sm.msg);
    sm.msg = NULL;
    sm.len = 0;
    sm.addr = 0;
    busy_serial = FALSE;
    post send_serial_message();
  }

  event void Sensor_0_Raw.readDone(error_t error, uint16_t data) {
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      save_sensor_data(data, 0);
    }
  }

  event void Sensor_1_Raw.readDone(error_t error, uint16_t data) {
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
  event void SerialSplitControl.startDone(error_t error) {}
  event void TestPhidgetAdcAppParams.receive_status(uint16_t status_flag) {}
  event void Sensor_0_Ctrl.startDone(error_t error){}
  event void Sensor_0_Ctrl.stopDone(error_t error){}
  event void Sensor_1_Ctrl.startDone(error_t error){}
  event void Sensor_1_Ctrl.stopDone(error_t error){}


  void clean_sensor_record(uint8_t id) {

    sensors[id].msg = NULL;
    sensors[id].pkt = NULL;
    sensors[id].len = sizeof(app_data_t) + (sensors[id].sample_count * sizeof(uint16_t));

    sensors[id].msg = call MessagePool.get();
    if (sensors[id].msg == NULL) {
      call Leds.led0On();
      return;
    }
    sensors[id].pkt = call NetworkAMSend.getPayload(sensors[id].msg, sensors[id].len);

    if (sensors[id].pkt == NULL) {
      call Leds.led0On();
      return;
    }

    sensors[id].seqno++;

    sensors[id].pkt->src = TOS_NODE_ID;
    sensors[id].pkt->seqno = sensors[id].seqno;
    sensors[id].pkt->sid = id;
    sensors[id].pkt->freq = sensors[id].freq;
    sensors[id].pkt->num = 0;
    memset(sensors[id].pkt->data, 0, (sensors[id].len));
  }

  void prepare_network_message(uint8_t id) {
    msg_queue_t q;

    /* Check if there is a space in queue */
    if (call NetworkQueue.full()) {
      /* Queue is full, give up sending the serial message */
      call Leds.led0On();
      return;
    }

    q.len = sensors[id].len;
    q.addr = call TestPhidgetAdcAppParams.get_destination();
    q.msg = sensors[id].msg;

    call NetworkQueue.enqueue(q);

    post send_network_message();
    
    clean_sensor_record(id);

  }


  void save_sensor_data(uint16_t data, uint8_t id) {
    if ((sensors[id].pkt == NULL) || (sensors[id].msg == NULL)) {
      call Leds.led0On();
      return;
    }

    sensors[id].pkt->data[sensors[id].pkt->num ] = data;

    sensors[id].pkt->num++;
    if (sensors[id].pkt->num < (sensors[id].sample_count)) {
      return;
    }

    prepare_network_message(id);
  }


  task void send_serial_message() {
    msg_queue_t *sm;

    /* Check if there is anything to send */
    if (call SerialQueue.empty()) {
      return;
    }

    if (busy_serial == TRUE) {
      return;
    }

    sm = call SerialQueue.headptr();

    /* Send message */

    if (call SerialAMSend.send(sm->addr, sm->msg, sm->len) != SUCCESS) {
      signal SerialAMSend.sendDone(sm->msg, FAIL);
    } else {
      busy_serial = TRUE;
      call Leds.led2Toggle();
    }
  }


  task void send_network_message() {
    msg_queue_t *nm;

    /* Check if there is anything to send */
    if (call NetworkQueue.empty()) {
      return;
    }

    nm = call NetworkQueue.headptr();

    if (call NetworkAMSend.send(nm->addr, nm->msg, nm->len) != SUCCESS) {
      /* Failed to send */
      signal NetworkAMSend.sendDone(nm->msg, FAIL);
    }
  }

  task void setup_app() {
    /* initialize sensors */
    uint8_t i;

    sensors[0].sample_count = call TestPhidgetAdcAppParams.get_s1_sampleCount();
    sensors[0].freq = call TestPhidgetAdcAppParams.get_s1_freq();
    sensors[0].seqno = 0;
    sensors[0].msg = NULL;
    call Sensor_0_Ctrl.set_rate(sensors[0].freq);
    call Sensor_0_Ctrl.set_signaling(TRUE);
    call Sensor_0_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s1_inputChannel());

    sensors[1].sample_count = call TestPhidgetAdcAppParams.get_s2_sampleCount();
    sensors[1].freq = call TestPhidgetAdcAppParams.get_s2_freq();
    sensors[1].seqno = 0;
    sensors[1].msg = NULL;
    call Sensor_1_Ctrl.set_rate(sensors[1].freq);
    call Sensor_1_Ctrl.set_signaling(TRUE);
    call Sensor_1_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());

    for (i=0; i < APP_MAX_NUMBER_OF_SENSORS; i++) {
      clean_sensor_record(i);
    }

    if (call Sensor_0_Ctrl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
      call Leds.led0On();
      return;
    }
    if (call Sensor_1_Ctrl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
      call Leds.led0On();
      return;
    }

    signal Mgmt.startDone(SUCCESS);
  }

}
