/*
 *  State Synchronization application module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2013 Marcin Szczodrak
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
 * Application: State Synchronization module
 * Author: Marcin Szczodrak
 * Date: 9/21/2013
 */


#include <Fennec.h>
#include "hashing.h"
#define POLICY_RESEND_RECONF		6

#define POLICY_RAND_MOD 	10
#define POLICY_RAND_OFFSET	1
#define POLICY_RAND_SEND	10
#define SAME_MSG_COUNTER_THRESHOLD 1

module StateSynchronizationAppP @safe() {
provides interface Mgmt;

uses interface StateSynchronizationAppParams;
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Fennec;
uses interface FennecWarnings;

uses interface Random;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint8_t same_msg_counter = 0;
uint16_t resend_confs = POLICY_RESEND_RECONF;
bool busy_sending = FALSE;
message_t confmsg;

task void schedule_state_sync_msg() {
	if (resend_confs == 0) {
		return;
	}

	same_msg_counter = 0;
	resend_confs--;
	call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 1);
}


task void reset_sync() {
	resend_confs = POLICY_RESEND_RECONF;
	post schedule_state_sync_msg();
}


task void send_state_sync_msg() {
	nx_struct FFControl *cu_msg;
	confmsg.conf = POLICY_CONFIGURATION;

	cu_msg = (nx_struct FFControl*) 
	call NetworkAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));
   
	if (same_msg_counter > SAME_MSG_COUNTER_THRESHOLD) {
		post schedule_state_sync_msg();
		return;
	}

	if (cu_msg == NULL) {
		post schedule_state_sync_msg();
		return;
	}

	cu_msg->seq = (nx_uint16_t) call Fennec.getStateSeq();
	cu_msg->conf_id = (nx_uint8_t) call Fennec.getStateId();

	// get crc of the FFControl and address
	cu_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq,
    				sizeof(nx_struct FFControl) - sizeof(cu_msg->crc));

	if (call NetworkAMSend.send(BROADCAST, &confmsg, sizeof(nx_struct FFControl)) != SUCCESS) {
		post schedule_state_sync_msg();
//		dbgs(F_CONTROL_UNIT, 0, DBGS_SEND_CONTROL_MSG_FAILED, 
//				call Fennec.getStateId(), call Fennec.getStateSeq());
	} else {
		busy_sending = TRUE;
//		dbgs(F_CONTROL_UNIT, 0, DBGS_SEND_CONTROL_MSG, 
//				call Fennec.getStateId(), call Fennec.getStateSeq());
	}
}


async event void FennecWarnings.detectWrongConfiguration() {
//	dbgs(F_CONTROL_UNIT, 0, DBGS_RECEIVE_WRONG_CONF_MSG, 0, 0);
	post reset_sync();
}

command error_t Mgmt.start() {
	dbg("ControlUnit", "Mgmt.start()");
	resend_confs = 0;  /* skip resending at the first time */
	confmsg.conf = POLICY_CONFIGURATION;
	busy_sending = FALSE;
	post reset_sync();
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("ControlUnit", "Mgmt.stop()");
	call Timer.stop();
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct FFControl *cu_msg = (nx_struct FFControl*) payload;

	if (cu_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq, 
						len - sizeof(cu_msg->crc))) {
		goto done_receive;
	}

	dbgs(F_CONTROL_UNIT, 0, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

//	if (!call PolicyCache.valid_policy_msg(cu_msg)) { /* check numn of confs */
//		goto done_receive;
//	}

	// First time receives Configuration
	if ( (call Fennec.getStateSeq() == CONFIGURATION_SEQ_UNKNOWN) && 
		(cu_msg->seq != CONFIGURATION_SEQ_UNKNOWN )) {
		goto reconfigure;
	} 

	/* Received configuration message with unknown sequence */
	if ((cu_msg->seq == CONFIGURATION_SEQ_UNKNOWN) && 
		(call Fennec.getStateSeq() != CONFIGURATION_SEQ_UNKNOWN)) {
		goto reset;
	}

	/* Received configuration message with lower sequence */
	if (cu_msg->seq < call Fennec.getStateSeq()) {
		goto reset;
	}

	/* Received configuration message with the same sequence number */
	if (cu_msg->seq == call Fennec.getStateSeq()) {
      
		/* Received same sequence with the same configuration id */
		if (cu_msg->conf_id == call Fennec.getStateId()) {
			same_msg_counter++;
			goto done_receive;
		}

		/* there is an inconsistency in a network */
		call Fennec.setStateAndSeq(call Fennec.getStateId(), call Fennec.getStateSeq() + 
		((call Random.rand16() % POLICY_RAND_MOD) + POLICY_RAND_OFFSET));
		goto reset;
	}

	/* Received configuration message with larger sequence number */
	if (cu_msg->seq > call Fennec.getStateSeq()) {
		goto reconfigure;
	}

reset:
	post reset_sync();
	goto done_receive;

reconfigure:
	call Fennec.setStateAndSeq(cu_msg->conf_id, cu_msg->seq);

done_receive:
	return msg;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	atomic busy_sending = FALSE;
	post schedule_state_sync_msg();
}

event void Timer.fired() {
	if (busy_sending == TRUE) {
		post schedule_state_sync_msg();
	} else {
		post send_state_sync_msg();
	}
}


event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {return msg;}

}
