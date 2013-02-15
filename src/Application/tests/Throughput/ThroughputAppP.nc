/*
 *  Throughput Test Application module for Fennec Fox platform.
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
 * Application: Throughput Test Application Module
 * Author: Marcin Szczodrak
 * Date: 1/21/2013
 * Last Modified: 1/21/2013
 */

module ThroughputAppP {
provides interface Mgmt;
provides interface Module;

uses interface ThroughputAppParams ;

/* Network interfaces */
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
uses interface ModuleStatus as NetworkStatus;

/* Serial Interfaces */ 
#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface Receive as SerialReceive;
uses interface SplitControl as SerialSplitControl;
#endif

uses interface Timer<TMilli> as Timer;
uses interface Leds;

/* Network Queue */
uses interface Queue<msg_queue_t> as NetworkQueue;

/* Serial Queue */
#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
uses interface Queue<msg_queue_t> as SerialQueue;
#endif

/* Message Pool */
uses interface Pool<message_t> as MessagePool;

}

implementation {

bool busy_serial;

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
task void send_serial_message();
#endif
task void send_network_message();
void prepare_network_message();

uint32_t seqno = 0;
bool init = 1;

#define MIN_ADDR 1
#define MAX_ADDR 17

/**
  * starting point for this module
  */
command error_t Mgmt.start() {
	init = 1;
	seqno = 0;
	busy_serial = FALSE;
//	if ((TOS_NODE_ID < MIN_ADDR) || (TOS_NODE_ID > MAX_ADDR)) {
//		signal Mgmt.startDone(SUCCESS);
//		return SUCCESS;
//	}

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
	/* check if this node will be sending messages over the serial */
	if ((TOS_NODE_ID == call ThroughputAppParams.get_destination()) || 
	        (NODE == call ThroughputAppParams.get_destination())) {
		/* if serial needed, initialize it */
		call SerialSplitControl.start();
	}
#endif

	call Timer.startOneShot(1000);
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	call Timer.stop();
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
#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
        message_t *serial_message;
        app_data_t *serial_data_payload;
        msg_queue_t sm;

	if (init) {
                return msg;
        }


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
                call MessagePool.put(serial_message);
                return msg;
        }

        /* Just add the message to the queue and wait */
        sm.msg = serial_message;
        sm.len = len;
        sm.addr = AM_BROADCAST_ADDR;
        call SerialQueue.enqueue(sm);

        post send_serial_message();
#endif
        return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
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
event void SerialSplitControl.stopDone(error_t errot){}
event void SerialSplitControl.startDone(error_t error) {}
#endif

event void Timer.fired() {
	if (init) {
		call Timer.startPeriodic(call ThroughputAppParams.get_freq());
		init = 0;
	}
	call Leds.led2Toggle();
        seqno++;
	prepare_network_message();
}

event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}
event void ThroughputAppParams.receive_status(uint16_t status_flag) {}

void prepare_network_message() {
        message_t *network_message;
        app_data_t *network_data_payload;
        msg_queue_t nm;

        if (call MessagePool.empty()) {
        /* well, there is not more memory space ... maybe increase pool queue */
                call Leds.led0On();
                return;
        }

        network_message = call MessagePool.get();
        if (network_message == NULL) {
        /* something went wrong.... this should never happen */
                call Leds.led0On();
                return;
        }

        network_data_payload = (app_data_t*)
                call NetworkAMSend.getPayload(network_message, sizeof(app_data_t)
                                        + call ThroughputAppParams.get_size());

        /* set network message content */
        network_data_payload->src = TOS_NODE_ID;
        network_data_payload->seqno = seqno;
        network_data_payload->freq = call ThroughputAppParams.get_freq();
        memset(network_data_payload->data, 0, call ThroughputAppParams.get_size());

        /* Check if there is a space in queue */
        if (call NetworkQueue.full()) {
                /* Queue is full, give up sending the serial message */
                call Leds.led0On();
                call MessagePool.put(network_message);
                return;
        }

        /* Just add the message to the queue and wait */
        nm.msg = network_message;
        nm.len = sizeof(app_data_t) + call ThroughputAppParams.get_size();
        nm.addr = call ThroughputAppParams.get_destination();
        call NetworkQueue.enqueue(nm);

        post send_network_message();
}


#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
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
		call Leds.led0On();
		signal SerialAMSend.sendDone(sm->msg, FAIL);
	} else {
		busy_serial = TRUE;
	}
}
#endif

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


}
