/*
 *  Bridge application module for Fennec Fox platform.
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
 * Application: Bridge Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "BridgeApp.h"

module BridgeAppP {
provides interface Mgmt;

uses interface BridgeAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {

task void send_serial_message();

command error_t Mgmt.start() {
	dbg("Application", "BridgeApp Mgmt.start()");
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("Application", "BridgeApp Mgmt.start()");
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

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
                call MessagePool.put(serial_message);
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
