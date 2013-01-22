/*
 *  Serial Test Application module for Fennec Fox platform.
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
 * Application: Serial Test Application Module
 * Author: Marcin Szczodrak
 * Date: 1/21/2013
 * Last Modified: 1/21/2013
 */

module SerialAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface SerialAppParams ;

  /* Network interfaces */
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface SensorCtrl as Temperature_Ctrl;
  uses interface SensorInfo as Temperature_Info;
  uses interface Read<ff_sensor_data_t> as Temperature_Read;

  uses interface SensorCtrl as Sensor_1_Ctrl;
  uses interface SensorInfo as Sensor_1_Info;
  uses interface AdcSetup as Sensor_1_Setup;
  uses interface Read<ff_sensor_data_t> as Sensor_1_Read;

  uses interface SensorCtrl as Sensor_2_Ctrl;
  uses interface SensorInfo as Sensor_2_Info;
  uses interface AdcSetup as Sensor_2_Setup;
  uses interface Read<ff_sensor_data_t> as Sensor_2_Read;
 
  /* Serial Interfaces */ 
  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds;

  /* Serial Queue */
  uses interface Queue<msg_queue_t> as SerialQueue;

  /* Message Pool */
  uses interface Pool<message_t> as MessagePool;

}

implementation {

bool busy_serial;

/**
  * starting point for this module
  */
command error_t Mgmt.start() {
	busy_serial = FALSE;
	/* check if this node will be sending messages over the serial */
	if ((TOS_NODE_ID == call SerialAppParams.get_destination()) || 
	        (NODE == call SerialAppParams.get_destination())) {
		/* if serial needed, initialize it */
		call SerialSplitControl.start();
	}

	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	call Timer.stop();
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

event void Timer.fired() {
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
}

event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}
event void SerialSplitControl.stopDone(error_t errot){}
event void SerialSplitControl.startDone(error_t error) {}
event void SerialAppParams.receive_status(uint16_t status_flag) {}

task void send_serial_message() {
	msg_queue_t *sm;

	/* Check if there is anything to send */
	if (call SerialQueue.empty()) {
		return;
	}

	if (busy_serial == TRUE) {
		//call Leds.led0On();
		return;
	}

	sm = call SerialQueue.headptr();

	/* Send message */

	if (call SerialAMSend.send(sm->addr, sm->msg, sm->len) != SUCCESS) {
		call Leds.led0On();
		signal SerialAMSend.sendDone(sm->msg, FAIL);
	} else {
		busy_serial = TRUE;
	}
}


}
