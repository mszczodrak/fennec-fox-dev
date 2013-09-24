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
uint16_t resend_confs = 0;
bool busy_sending = FALSE;
message_t confmsg;

task void schedule_state_sync_msg() {
	if (resend_confs == 0) {
		dbg("StateSynchronization", "StateSynchronizationAppP scheduled_state_sync_msg - finished()");
		return;
	}

	same_msg_counter = 0;
	resend_confs--;
	call Timer.startOneShot(call Random.rand16() % 
		call StateSynchronizationAppParams.get_send_delay() + 1);
}


task void reset_sync() {
	dbg("StateSynchronization", "StateSynchronizationAppP reset_sync");
	resend_confs = call StateSynchronizationAppParams.get_resend();
	post schedule_state_sync_msg();
}


task void send_state_sync_msg() {
	nx_struct FFControl *cu_msg;
	dbg("StateSynchronization", "StateSynchronizationAppP send_state_sync_msg()");

	cu_msg = (nx_struct FFControl*) 
	call NetworkAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));
   
	if (same_msg_counter > call StateSynchronizationAppParams.get_supress()) {
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
		dbg("StateSynchronization", "StateSynchronizationAppP send_state_sync_msg() - FAIL");
//		dbgs(F_CONTROL_UNIT, 0, DBGS_SEND_CONTROL_MSG_FAILED, 
//				call Fennec.getStateId(), call Fennec.getStateSeq());
	} else {
		busy_sending = TRUE;
		dbg("StateSynchronization", "StateSynchronizationAppP send_state_sync_msg() - SUCCESS");
//		dbgs(F_CONTROL_UNIT, 0, DBGS_SEND_CONTROL_MSG, 
//				call Fennec.getStateId(), call Fennec.getStateSeq());
	}
}


async event void FennecWarnings.detectWrongConfiguration() {
//	dbgs(F_CONTROL_UNIT, 0, DBGS_RECEIVE_WRONG_CONF_MSG, 0, 0);
	dbg("StateSynchronization", "StateSynchronizationAppP FennecWarnings.detectWrongConfiguration()");
	post reset_sync();
}

command error_t Mgmt.start() {
	dbg("StateSynchronization", "StateSynchronizationAppP Mgmt.start()");
	busy_sending = FALSE;
	post reset_sync();
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("StateSynchronization", "StateSynchronizationAppP Mgmt.stop()");
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
	dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive(0x%1x, 0x%1x, %d)",
				msg, payload, len);

	dbgs(F_CONTROL_UNIT, 0, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

//	if (!call PolicyCache.valid_policy_msg(cu_msg)) { /* check numn of confs */
//		goto done_receive;
//	}

	// First time receives Configuration
	if ( (call Fennec.getStateSeq() == CONFIGURATION_SEQ_UNKNOWN) && 
		(cu_msg->seq != CONFIGURATION_SEQ_UNKNOWN )) {
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - first time");
		goto reconfigure;
	} 

	/* Received configuration message with unknown sequence */
	if ((cu_msg->seq == CONFIGURATION_SEQ_UNKNOWN) && 
		(call Fennec.getStateSeq() != CONFIGURATION_SEQ_UNKNOWN)) {
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - msg with unknown seq");
		goto reset;
	}

	/* Received configuration message with lower sequence */
	if (cu_msg->seq < call Fennec.getStateSeq()) {
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - reset");
		goto reset;
	}

	/* Received configuration message with the same sequence number */
	if (cu_msg->seq == call Fennec.getStateSeq()) {
      
		/* Received same sequence with the same configuration id */
		if (cu_msg->conf_id == call Fennec.getStateId()) {
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - same seq");
			same_msg_counter++;
			goto done_receive;
		}

		/* there is an inconsistency in a network */
		call Fennec.setStateAndSeq(call Fennec.getStateId(), 
			call Fennec.getStateSeq() + ((call Random.rand16() % 
			call StateSynchronizationAppParams.get_rand_seq_mod()) + 
			call StateSynchronizationAppParams.get_rand_seq_offset()));
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - inconsistency");
		goto reset;
	}

	/* Received configuration message with larger sequence number */
	if (cu_msg->seq > call Fennec.getStateSeq()) {
		dbg("StateSynchronization", "StateSynchronizationAppP NetworkReceive.receive - reconfigure");
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
	dbg("StateSynchronization", "StateSynchronizationAppP NetworkAMSend.sendDone(0x%1x, %d)",
			msg, error);
	busy_sending = FALSE;
	post schedule_state_sync_msg();
}

event void Timer.fired() {
	dbg("StateSynchronization", "StateSynchronizationAppP Timer.fired()");
	if (busy_sending == TRUE) {
		post schedule_state_sync_msg();
	} else {
		post send_state_sync_msg();
	}
}


event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {return msg;}

}
