/*
 * Application: Fennec Fox Control Unit
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include <Fennec.h>
#include "hashing.h"
#define POLICY_RESEND_RECONF		6

#define POLICY_RAND_MOD 	10
#define POLICY_RAND_OFFSET	1
#define POLICY_RAND_SEND	10
#define SAME_MSG_COUNTER_THRESHOLD 1

module ControlUnitAppP @safe() {
provides interface SimpleStart;
provides interface Mgmt;

uses interface ControlUnitAppParams;
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
uses interface ModuleStatus as NetworkStatus;

uses interface Mgmt as FennecEngine;
uses interface Mgmt as EventsMgmt;

uses interface EventCache;
uses interface PolicyCache;

uses interface Random;
uses interface Timer<TMilli> as Timer;
}

implementation {

uint16_t configuration_id = UNKNOWN_CONFIGURATION;
uint16_t configuration_seq = 0;
uint8_t same_msg_counter = 0;
uint16_t resend_confs = POLICY_RESEND_RECONF;
bool busy_sending = FALSE;

message_t confmsg;

norace uint8_t status = S_NONE;
task void sendConfigurationMsg();

task void report_new_configuration() {
	/*
	dbgs(F_CONTROL_UNIT, status, DBGS_RECEIVE_AND_RECONFIGURE,
                              configuration_id, configuration_seq);
	*/
}

void start_policy_send() {
	atomic same_msg_counter = 0;
	call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 1);
}

void reset_control() {
	resend_confs = POLICY_RESEND_RECONF;
	start_policy_send();
}

void set_new_state(state_t conf, uint16_t seq) {
	configuration_seq = seq;
	configuration_id = conf;
	call Timer.stop();
	switch(status) {
	case S_STOPPED:
		/* Everything is stopped */
		insertLog(F_CONTROL_UNIT, S_STARTING);
		status = S_STARTING;
		resend_confs = POLICY_RESEND_RECONF;
		/* Start Policy State */
		call PolicyCache.set_active_configuration(POLICY_CONF_ID);
		call FennecEngine.start();
		break;

	case S_NONE:
		resend_confs = 0;  /* skip resending at the first time */
		call PolicyCache.set_active_configuration(POLICY_CONF_ID);
		call FennecEngine.start();
		break;

	case S_COMPLETED:
		/* Here we start our journey once a new state is detected */
		insertLog(F_CONTROL_UNIT, S_INIT);
		status = S_INIT;
		post report_new_configuration();
		insertLog(F_EVENTS, S_STOPPING);
		call EventsMgmt.stop();
		//reset_control();
		break;

	case S_INIT:
		/* Here we are done with sending control messages and we
		 * moving into stopping all modules of the stack */
		insertLog(F_CONTROL_UNIT, S_STOPPING);
		status = S_STOPPING;
		call EventCache.clearMask();
		call FennecEngine.stop();
		break;
	}
}

task void continue_reconfiguration() {
	atomic if (resend_confs > 0) resend_confs--;
	if (resend_confs > 0) {
		start_policy_send();
		return;
	}

	switch(status) {
	case S_INIT:
		set_new_state(configuration_id, configuration_seq);
		break;

	case S_STARTED:
		/* at this point the control stack is running, now start the rest,
		 * set configuration to the new state and start events and the stack
		 * itself 
		 */
		call PolicyCache.set_active_configuration(configuration_id);
		insertLog(F_EVENTS, S_STARTING);
		call EventsMgmt.start();
		//call FennecEngine.start();
		break;

	case S_COMPLETED:
		/* stay here... no change */

	default:
	}
}

command void SimpleStart.start() {
	configuration_id = UNKNOWN_CONFIGURATION;
	configuration_seq = 0;
	confmsg.conf = POLICY_CONFIGURATION;
	busy_sending = FALSE;
	status = S_NONE;
	signal SimpleStart.startDone(SUCCESS);
}

event void PolicyCache.newConf(conf_t new_conf) {
	insertLog(F_CONTROL_UNIT, S_NEW_STATE);
	set_new_state(new_conf, configuration_seq + 1);
}

event void PolicyCache.wrong_conf() {
	/*
	dbgs(F_CONTROL_UNIT, status, DBGS_RECEIVE_WRONG_CONF_MSG,
					configuration_id, configuration_seq);
	*/
	reset_control();
}

event void EventsMgmt.stopDone(error_t err) {
	if (err != SUCCESS) { 
		call EventsMgmt.stop();
		return;
	}
	insertLog(F_EVENTS, S_STOPPED);
	reset_control();
}

event void EventsMgmt.startDone(error_t err) {
	if (err != SUCCESS) { 
		call EventsMgmt.start();
		return;
	}
	insertLog(F_EVENTS, S_STARTED);
	call FennecEngine.start();
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct FFControl *cu_msg = (nx_struct FFControl*) payload;

	if (cu_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq, 
						len - sizeof(cu_msg->crc))) {
		goto done_receive;
	}

	//dbgs(F_CONTROL_UNIT, status, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

	if (!call PolicyCache.valid_policy_msg(cu_msg)) {
		goto done_receive;
	}

	if ((status != S_STARTED) && (status != S_COMPLETED)) {
		goto done_receive;
	}

	// First time receives Configuration
	if ( configuration_seq == CONFIGURATION_SEQ_UNKNOWN && cu_msg->seq != CONFIGURATION_SEQ_UNKNOWN ) {
		goto reconfigure;
	} 

	/* Received configuration message with unknown sequence */
	if ( cu_msg->seq == CONFIGURATION_SEQ_UNKNOWN && configuration_seq != CONFIGURATION_SEQ_UNKNOWN ) {
		goto reset;
	}

	/* Received configuration message with lower sequence */
	if (cu_msg->seq < configuration_seq) {
		goto reset;
	}

	/* Received configuration message with the same sequence number */
	if (cu_msg->seq == configuration_seq) {
      
		/* Received same sequence with the same configuration id */
		if (cu_msg->conf_id == configuration_id) {
			same_msg_counter++;
			goto done_receive;
		}

		/* there is an inconsistency in a network */
		configuration_seq += (call Random.rand16() % POLICY_RAND_MOD) + POLICY_RAND_OFFSET;
		goto reset;
	}

	/* Received configuration message with larger sequence number */
	if (cu_msg->seq > configuration_seq) {
		goto reconfigure;
	}

reset:
	reset_control();
	goto done_receive;

reconfigure:
	if ((cu_msg->conf_id != configuration_id) && 
		(cu_msg->conf_id < call PolicyCache.get_number_of_configurations()) ){
		set_new_state(cu_msg->conf_id, cu_msg->seq);
	}

done_receive:
	return msg;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	atomic busy_sending = FALSE;
	if (error != SUCCESS) {
		start_policy_send();
	} else {
		post continue_reconfiguration();
	}
}

event void Timer.fired() {
	if (busy_sending == TRUE) {
		start_policy_send();
	} else {
		post sendConfigurationMsg();
	}
}

event void FennecEngine.startDone(error_t err) {
	if (err != SUCCESS) {
		call FennecEngine.start();
		return;
	}

	switch(status) {
	case S_NONE:
		status = S_STARTING;
		post report_new_configuration();

	case S_STARTING:
		insertLog(F_CONTROL_UNIT, S_STARTED);
		status = S_STARTED;
		call PolicyCache.set_active_configuration(configuration_id);
		post continue_reconfiguration();
		break;

	case S_STARTED:
		insertLog(F_CONTROL_UNIT, S_COMPLETED);
		printLog();
		status = S_COMPLETED;
		break;

	default:
	}
}

event void FennecEngine.stopDone(error_t err) {
	if (err != SUCCESS) {
		call FennecEngine.stop();
		return;
	}

	switch(status) {
	case S_STOPPING:
		/* The configuration has been stopped, now stop the control state */
		status = S_STOPPED;
		call PolicyCache.set_active_configuration(POLICY_CONF_ID);
		call FennecEngine.stop();
		break;
      
	case S_STOPPED:
		/* At this moment everything is stopped */
		set_new_state(configuration_id, configuration_seq);
		break;

	default:
	}
}


task void sendConfigurationMsg() {
	nx_struct FFControl *cu_msg;
	confmsg.conf = POLICY_CONFIGURATION;

	cu_msg = (nx_struct FFControl*) 
	call NetworkAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));
   
	if (same_msg_counter > SAME_MSG_COUNTER_THRESHOLD) {
		post continue_reconfiguration();
		return;
	}

	if (cu_msg == NULL) {
		post continue_reconfiguration();
		return;
	}

	cu_msg->seq = (nx_uint16_t) configuration_seq;
	cu_msg->conf_id = (nx_uint8_t) configuration_id;

	// get crc of the FFControl and address
	cu_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq,
    				sizeof(nx_struct FFControl) - sizeof(cu_msg->crc));

	if (call NetworkAMSend.send(AM_BROADCAST_ADDR, &confmsg, sizeof(nx_struct FFControl)) != SUCCESS) {
		start_policy_send();
		//dbgs(F_CONTROL_UNIT, status, DBGS_SEND_CONTROL_MSG_FAILED, configuration_id, configuration_seq);
	} else {
		busy_sending = TRUE;
		//dbgs(F_CONTROL_UNIT, status, DBGS_SEND_CONTROL_MSG, configuration_id, configuration_seq);
	}
}


command error_t Mgmt.start() {
	insertLog(F_APPLICATION, S_STARTING);
	insertLog(F_APPLICATION, S_STARTED);
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	insertLog(F_APPLICATION, S_STOPPING);
	insertLog(F_APPLICATION, S_STOPPED);
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {return msg;}
event void ControlUnitAppParams.receive_status(uint16_t status_flag) {}
event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}

}
