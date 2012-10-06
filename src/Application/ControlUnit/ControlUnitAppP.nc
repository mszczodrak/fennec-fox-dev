/*
 * Application: Fennec Fox Control Unit
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include <Fennec.h>
#include "hashing.h"
#define POLICY_LED	1
#define POLICY_RESEND_RECONF		300
#define POLICY_MIN_RESEND_RECONF 	30
#define POLICY_MAX_WRONG_CONFS		5

#define POLICY_RESEND_MIN	5
#define POLICY_RAND_MOD 	10
#define POLICY_RAND_OFFSET	1
#define POLICY_RAND_SEND	20
#define SAME_MSG_COUNTER_THRESHOLD 2
#define POLICY_MAX_RECEIVE	10

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

  norace uint8_t status = S_STOPPED;
  task void sendConfigurationMsg();

  void reset_control() {
    if (!call Timer.isRunning()) {
      resend_confs = POLICY_MIN_RESEND_RECONF;
      same_msg_counter = 0;
      same_msg_counter = 0;
      call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 1);
    }
  }

  void start_policy_send() {
    same_msg_counter = 0;
    call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 6);
  }

  void set_new_state(state_t conf, uint16_t seq) {
    call Timer.stop();
    configuration_seq = seq;
    configuration_id = conf;
    switch(status) {
      case S_STOPPED:
        status = S_STARTING;
        resend_confs = POLICY_RESEND_RECONF;
        call PolicyCache.set_active_configuration(POLICY_CONF_ID);
        call FennecEngine.start();
        break;

      case S_COMPLETED:
        status = S_INIT;
        call EventsMgmt.stop();
        reset_control();
        break;

      case S_INIT:
        status = S_STOPPING;
        call EventCache.clearMask();
        call FennecEngine.stop();
        break;
    }
  }

  task void continue_reconfiguration() {
    if (resend_confs > 0) resend_confs--;
    if (resend_confs > 0) {
      //printf("cr %d\n", resend_confs);
      start_policy_send();
    } else {
      switch(status) {
        case S_INIT:
          set_new_state(configuration_id, configuration_seq);
          break;

        case S_STARTED:
          call PolicyCache.set_active_configuration(configuration_id);
          call EventsMgmt.start();
          call FennecEngine.start();
          break;

        default:
      }
    }
  }


  command void SimpleStart.start() {
    configuration_id = UNKNOWN_CONFIGURATION;
    configuration_seq = 0;
    confmsg.conf = POLICY_CONFIGURATION;
    busy_sending = FALSE;
    status = S_STOPPED;
    signal SimpleStart.startDone(SUCCESS);
  }

  event void PolicyCache.newConf(conf_t new_conf) {
    //printf("new conf\n");
    //printfflush();
    set_new_state(new_conf, configuration_seq + 1);
    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_AND_RECONFIGURE, 
				new_conf, configuration_seq + 1);
  }

  event void PolicyCache.wrong_conf() {
    //printf("wrong conf\n");
    //printfflush();
    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_WRONG_CONF_MSG, 0, 0);
    reset_control();
  }

  event void EventsMgmt.stopDone(error_t err) {
    if (err != SUCCESS) { 
      call EventsMgmt.stop();
    }
  }

  event void EventsMgmt.startDone(error_t err) {
    if (err != SUCCESS) { 
      call EventsMgmt.start();
    }
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    nx_struct FFControl *cu_msg = (nx_struct FFControl*) payload;

    //printf("receive\n");
    //printfflush();

    if (cu_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq, 
						len - sizeof(cu_msg->crc))) {
      goto done_receive;
    }

    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

    if (!call PolicyCache.valid_policy_msg(cu_msg)) {
      goto done_receive;
    }

    if (resend_confs > POLICY_RESEND_MIN) {
      resend_confs = POLICY_RESEND_MIN;
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
      
      if (cu_msg->conf_id == configuration_id) {
        /* Received same sequence with the same configuration id */
	if (++same_msg_counter > POLICY_MAX_RECEIVE) {
	  start_policy_send();
	}
	
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
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_AND_RECONFIGURE, cu_msg->seq, cu_msg->conf_id);
    }

done_receive:
    return msg;
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    busy_sending = FALSE;
    same_msg_counter = 0;
    if (error != SUCCESS) {
      //printf("sendDone - FAILED\n");
      //printfflush();
      call Timer.startOneShot(1);
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
    if (err == SUCCESS) {
      switch(status) {
        case S_STARTING:
          status = S_STARTED;
          call PolicyCache.set_active_configuration(configuration_id);
          post continue_reconfiguration();
          break;

        case S_STARTED:
          status = S_COMPLETED;
      }
    } else {
      call FennecEngine.start();
    }
  }

  event void FennecEngine.stopDone(error_t err) {
    if (err == SUCCESS) {
      switch(status) {
        case S_STOPPING:
          status = S_STOPPED;
          call PolicyCache.set_active_configuration(POLICY_CONF_ID);
          call FennecEngine.stop();
          break;
      
        case S_STOPPED:
          set_new_state(configuration_id, configuration_seq);
          break;
      }
    } else {
      call FennecEngine.stop();
    }
  }


  task void sendConfigurationMsg() {

    nx_struct FFControl *cu_msg;
    confmsg.conf = POLICY_CONFIGURATION;
    cu_msg = (nx_struct FFControl*) call NetworkAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));
    
    if (same_msg_counter > SAME_MSG_COUNTER_THRESHOLD) {
      same_msg_counter = 0;
      post continue_reconfiguration();
      return;
    }

    if (cu_msg == NULL) {
      return;
    }

    cu_msg->seq = (nx_uint16_t) configuration_seq;
    cu_msg->conf_id = (nx_uint8_t) configuration_id;

    // get crc of the FFControl and address
    cu_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq,
    				sizeof(nx_struct FFControl) - sizeof(cu_msg->crc));

    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_SEND_CONTROL_MSG, configuration_seq, configuration_id);

    if (call NetworkAMSend.send(AM_BROADCAST_ADDR, &confmsg, sizeof(nx_struct FFControl)) != SUCCESS) {
      //printf("failed.  \n");
      //printfflush();
      call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 500);
    } else {
      busy_sending = TRUE;
      //same_msg_counter = 0;
    }
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }

  command error_t Mgmt.start() {
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void ControlUnitAppParams.receive_status(uint16_t status_flag) {
  }


}
