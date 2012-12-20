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
  uses interface Queue<app_network_internal_t> as NetworkQueue;

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
    printf("dst %d\n", call TestPhidgetAdcAppParams.get_destination());
    /* check if this node will be sending messages over the serial */
    if ((TOS_NODE_ID == call TestPhidgetAdcAppParams.get_destination()) || 
	        (NODE == call TestPhidgetAdcAppParams.get_destination())) {
      /* if serial needed, initialize it */
      call SerialSplitControl.start();
    } else {
      /* if serial not needed, fake the readiness of the serial and move on */
      signal SerialSplitControl.startDone(SUCCESS);
    }

    post setup_app();

    return SUCCESS;
  }


  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    if(error == SUCCESS){
      app_network_internal_t nm = call NetworkQueue.dequeue();
      call MessagePool.put(nm.msg);
      nm.msg = NULL;
    } 
    post send_network_message();
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
    if(error == SUCCESS){
      app_serial_internal_t sm = call SerialQueue.dequeue();
      call MessagePool.put(sm.msg);
      busy_serial = FALSE;
    } 
    post send_serial_message();
  }

  event void Sensor_1_Raw.readDone(error_t error, uint16_t data) {
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      save_sensor_data(data, 0);
    }
  }

  event void Sensor_2_Raw.readDone(error_t error, uint16_t data) {
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
  event void Sensor_1_Ctrl.startDone(error_t error){}
  event void Sensor_1_Ctrl.stopDone(error_t error){}
  event void Sensor_2_Ctrl.startDone(error_t error){}
  event void Sensor_2_Ctrl.stopDone(error_t error){}

  void clean_sensor_record(uint8_t id) {
     memset(sensors[id].pkt.data, 0, (sensors[id].sample_count * sizeof(uint16_t)));
     sensors[id].pkt.num = 0;
     sensors[id].pkt.sid = id;
     sensors[id].pkt.freq = sensors[id].freq;
  }

  void save_sensor_data(uint16_t data, uint8_t id) {
    app_data_t *msg_ptr;

    sensors[id].pkt.data[sensors[id].pkt.num ] = data;

    printf("sd %d %d %d\n", sensors[id].pkt.num, id, sensors[id].sample_count);

    if (sensors[id].pkt.num < (sensors[id].sample_count - 1)) {
      sensors[id].pkt.num++;
      printf("more\n");
      return;
    }

    printfflush();
    /* Check if there is a space in queue */
    if (call NetworkQueue.full()) {
      printf("nq full\n");
      /* Queue is full, give up sending the serial message */
      call Leds.led0On();
      return;
    }

    /* check if it's not sending an old message */
    if (sensors[id].msg != NULL) {
      printf("nq busy\n");
      call Leds.led0On();
      return;
    }

    sensors[id].len = sizeof(app_data_t) +
                                (sensors[id].sample_count * sizeof(uint16_t));

    /* prepare network message */
    if (call MessagePool.empty()) {
      printf("mp empty\n");
      call Leds.led0On();
      return;
    }

    sensors[id].msg = call MessagePool.get();

    if (sensors[id].msg == NULL) {
      call Leds.led0On();
      return;
    }

    msg_ptr = (app_data_t*) call NetworkAMSend.getPayload(sensors[id].msg, sensors[id].len);

    if (msg_ptr == NULL) {
      call MessagePool.put(sensors[id].msg);
      return;
    }

    memcpy(msg_ptr, &sensors[id].pkt, sensors[id].len);
    clean_sensor_record(id);

    call NetworkQueue.enqueue(sensors[id]);

    post send_network_message();
  }


  task void send_serial_message() {
    printf("ss\n");
    printfflush();

    /* Check if there is anything to send */
    if (call SerialQueue.empty()) {
      return;
    }

    if (busy_serial == TRUE) {
      return;
    }

    /* Send message */
    if (call SerialAMSend.send(AM_BROADCAST_ADDR, (call SerialQueue.head()).msg,
				(call SerialQueue.head()).len) != SUCCESS) {
      post send_serial_message();
    } else {
      busy_serial = TRUE;
      call Leds.led1Toggle(); /*red led*/
    }
  }


  task void send_network_message() {
    app_network_internal_t *ptr;
    /* Check if there is anything to send */
    if (call NetworkQueue.empty()) {
      return;
    }

    ptr = call NetworkQueue.headptr();


    /**
     * if the sensor samples should be send to this node
     * (meaning, this node is the gatway), signal message receive.
     */
//    if (NODE == call TestPhidgetAdcAppParams.get_destination()) {
//        signal NetworkReceive.receive(ptr->msg,
//		call NetworkAMSend.getPayload(ptr->msg, ptr->len), ptr->len);
//      signal NetworkAMSend.sendDone(ptr->msg, SUCCESS);
//      return;
//    }

    printf("sn\n");

    if (call NetworkAMSend.send(call TestPhidgetAdcAppParams.get_destination(),
				                ptr->msg, ptr->len) != SUCCESS) {
      /* Failed to send */
      signal NetworkAMSend.sendDone(ptr->msg, FAIL);
    }
  }

  task void setup_app() {
    /* initialize sensors */
    uint8_t i;

    sensors[0].sample_count = call TestPhidgetAdcAppParams.get_s1_sampleCount();
    printf("sc0 %d\n", call TestPhidgetAdcAppParams.get_s1_sampleCount());
    sensors[0].freq = call TestPhidgetAdcAppParams.get_s1_freq();
    sensors[0].seqno = 0;
    call Sensor_1_Ctrl.set_rate(sensors[0].freq);
    call Sensor_1_Ctrl.set_signaling(TRUE);
    call Sensor_1_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s1_inputChannel());

    printf("S0 - %d %d %d\n",sensors[0].sample_count, sensors[0].freq, sensors[0].seqno);

    sensors[1].sample_count = call TestPhidgetAdcAppParams.get_s2_sampleCount();
    sensors[1].freq = call TestPhidgetAdcAppParams.get_s2_freq();
    sensors[1].seqno = 0;
    call Sensor_2_Ctrl.set_rate(sensors[1].freq);
    call Sensor_2_Ctrl.set_signaling(TRUE);
    call Sensor_2_Setup.set_input_channel(call TestPhidgetAdcAppParams.get_s2_inputChannel());

    printf("S1 - %d %d %d\n", sensors[1].sample_count, sensors[1].freq, sensors[1].seqno);
    printfflush();

    for (i=0; i < APP_MAX_NUMBER_OF_SENSORS; i++) {
      clean_sensor_record(i);
      sensors[i].msg = NULL;
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

    signal Mgmt.startDone(SUCCESS);
  }

}
