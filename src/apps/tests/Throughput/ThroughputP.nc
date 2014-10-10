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
  * Throughput Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

generic module ThroughputP(process_t process) {
provides interface SplitControl;
provides interface Module;

uses interface Param;

/* Sub interfaces */
uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface ModuleStatus as SubStatus;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;


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

/* Sub Queue */
uses interface Queue<msg_queue_t> as SubQueue;

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

uint8_t size;
uint32_t freq;
uint16_t destination;


/**
  * starting point for this module
  */
command error_t SplitControl.start() {
	init = 1;
	seqno = 0;
	busy_serial = FALSE;

/*
	if ((TOS_NODE_ID < MIN_ADDR) || (TOS_NODE_ID > MAX_ADDR)) {
		signal SplitControl.startDone(SUCCESS);
		return SUCCESS;
	}
*/

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
	/* check if this node will be sending messages over the serial */
	call Param.get(DESTINATION, &destination, sizeof(destination));
	if ((TOS_NODE_ID == destination) || (NODE == destination)) {
		/* if serial needed, initialize it */
		call SerialSplitControl.start();
	}
#endif

	call Timer.startOneShot(1000);
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void SubAMSend.sendDone(message_t *msg, error_t error) {
        /* we do not check for error, if failed to send a message, we drop
         * that message anyway
         */
        msg_queue_t nm = call SubQueue.dequeue();
        call MessagePool.put(nm.msg);
        nm.msg = NULL;
        nm.len = 0;
        nm.addr = 0;

        post send_network_message();
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
        message_t *serial_message;
        app_data_t *serial_data_payload;
        msg_queue_t sm;

	if (init) {
                return msg;
        }


        if (call MessagePool.empty()) {
        /* well, there is not more memory space ... maybe increase pool queue */
                return msg;
        }

        serial_message = call MessagePool.get();
        if (serial_message == NULL) {
        /* something went wrong.... this should never happen */
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

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
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
	call Param.get(FREQ, &freq, sizeof(freq));
	if (init) {
		call Timer.startPeriodic(freq);
		init = 0;
	}
        seqno++;
	prepare_network_message();
}

event void SubStatus.status(uint8_t layer, uint8_t status_flag) {}

void prepare_network_message() {
        message_t *network_message;
        app_data_t *network_data_payload;
        msg_queue_t nm;

        if (call MessagePool.empty()) {
        /* well, there is not more memory space ... maybe increase pool queue */
                return;
        }

        network_message = call MessagePool.get();
        if (network_message == NULL) {
        /* something went wrong.... this should never happen */
                return;
        }

	call Param.get(SIZE, &size, sizeof(size));
	call Param.get(FREQ, &freq, sizeof(freq));
	call Param.get(DESTINATION, &destination, sizeof(destination));

        network_data_payload = (app_data_t*)
                call SubAMSend.getPayload(network_message, sizeof(app_data_t) + size);

        /* set network message content */
        network_data_payload->src = TOS_NODE_ID;
        network_data_payload->seqno = seqno;
        network_data_payload->freq = freq;
        memset(network_data_payload->data, 0, size);

        /* Check if there is a space in queue */
        if (call SubQueue.full()) {
                /* Queue is full, give up sending the serial message */
                call MessagePool.put(network_message);
                return;
        }

        /* Just add the message to the queue and wait */
        nm.msg = network_message;
        nm.len = sizeof(app_data_t) + size;
        nm.addr = destination;
        call SubQueue.enqueue(nm);

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
		signal SerialAMSend.sendDone(sm->msg, FAIL);
	} else {
		busy_serial = TRUE;
	}
}
#endif

task void send_network_message() {
        msg_queue_t *nm;

        /* Check if there is anything to send */
        if (call SubQueue.empty()) {
                return;
        }

        nm = call SubQueue.headptr();

        if (call SubAMSend.send(nm->addr, nm->msg, nm->len) != SUCCESS) {
                /* Failed to send */
                signal SubAMSend.sendDone(nm->msg, FAIL);
        }
}


}
