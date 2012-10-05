/*
 * Copyright (c) 2009-2011 Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Application: Fennec Fox Control Unit
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include <Fennec.h>
#include "hashing.h"
#define POLICY_LED	1
#define POLICY_RESEND_RECONF	6
#define POLICY_MAX_WRONG_CONFS	5

#define POLICY_RAND_MOD 	10
#define POLICY_RAND_OFFSET	1
#define POLICY_RAND_SEND	20
#define SAME_MSG_COUNTER_THRESHOLD 2

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

  uses interface EventCache;
  uses interface PolicyCache;

  uses interface Random;
  uses interface Timer<TMilli> as Timer;
}

implementation {

  uint16_t configuration_id = UNKNOWN_CONFIGURATION;
  uint16_t configuration_seq = 0;
  uint8_t same_msg_counter;
  bool enable_policy_control_support = FALSE;
  uint8_t resend_confs = POLICY_RESEND_RECONF;

  message_t confmsg;

  norace uint8_t status = S_STOPPED;


  task void sendConfigurationMsg();
  task void start_engine();
  task void stop_engine();


  void start_policy_send() {
    call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND + 1);
  }


  void set_new_state(state_t conf, uint16_t seq) {
    call Timer.stop();
    atomic {
      resend_confs = POLICY_RESEND_RECONF;
      configuration_seq = seq;
      if (configuration_id == UNKNOWN_CONFIGURATION) {
        /* First time here */
        configuration_id = conf;
        enable_policy_control_support = TRUE;
        post start_engine();
      } else {
        configuration_id = conf;
        post stop_engine();
      }
    }
  }

  command void SimpleStart.start() {
    configuration_id = UNKNOWN_CONFIGURATION;
    configuration_seq = 0;
    enable_policy_control_support = FALSE;
    confmsg.conf = POLICY_CONFIGURATION;
    set_new_state(get_state_id(), CONFIGURATION_SEQ_UNKNOWN);
    signal SimpleStart.startDone(SUCCESS);
  }

  event void PolicyCache.newConf(conf_t new_conf) {
    set_new_state(new_conf, configuration_seq + 1);
  }

  event void PolicyCache.wrong_conf() {
    start_policy_send();
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    nx_struct FFControl *cu_msg = (nx_struct FFControl*) payload;

    printf("receive\n");
    printfflush();

    if (cu_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq, 
						len - sizeof(cu_msg->crc))) {
      goto done_receive;
    }

    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

    if (!call PolicyCache.valid_policy_msg(cu_msg)) {
      goto done_receive;
    }

    if (status != S_STARTED) {
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
        if (call Timer.isRunning()) {
	  same_msg_counter++;
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
    if (!call Timer.isRunning()) {
      resend_confs = POLICY_RESEND_RECONF;
      same_msg_counter = 0;
      start_policy_send();
    }
    goto done_receive;

reconfigure:
    if ((cu_msg->conf_id != configuration_id) && 
	(cu_msg->conf_id < call PolicyCache.get_number_of_configurations())
                                			) {
      set_new_state(cu_msg->conf_id, cu_msg->seq);
    }

done_receive:
    return msg;
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    same_msg_counter = 0;
    if (error != SUCCESS) {
      printf("sendDone - FAILED\n");
      start_policy_send();
    } else {
      if (resend_confs > 0) resend_confs--;
      printf("sendDone - SUCCESS r%d\n", resend_confs);
      if (resend_confs > 0) {
        start_policy_send();
      }
    }
    printfflush();
    
  }

  event void Timer.fired() {
    post sendConfigurationMsg();
  }


  event void FennecEngine.startDone(error_t err) {
    if (err == SUCCESS) {
      if (enable_policy_control_support == TRUE) {
        enable_policy_control_support = FALSE;
        post start_engine();
      } else {
        status = S_STARTED;
        call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND);
      }
    } else {
      call FennecEngine.start();
    }
  }

  event void FennecEngine.stopDone(error_t err) {
    if (err == SUCCESS) {
      //printf("FennecEngine stopDone\n");
      enable_policy_control_support = TRUE;
      post start_engine();
    } else {
      call FennecEngine.stop();
    }
  }

  task void start_engine() {
    if (enable_policy_control_support == TRUE) {
      call PolicyCache.set_active_configuration(POLICY_CONF_ID);
      //printf("start_engine - %d\n", POLICY_CONF_ID);
    } else {
      call PolicyCache.set_active_configuration(configuration_id);
      //printf("start_engine - %d\n", configuration_id);
    }
    //printfflush();
    call FennecEngine.start();
  }

  task void stop_engine() {
    atomic status = S_STOPPED;
    call EventCache.clearMask();
    call FennecEngine.stop();
  }


  task void sendConfigurationMsg() {

    nx_struct FFControl *cu_msg = (nx_struct FFControl*) call NetworkAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));
    
    if (same_msg_counter > SAME_MSG_COUNTER_THRESHOLD) {
      if (resend_confs > 0) resend_confs--;
      if (resend_confs > 0) {
        start_policy_send();
      }
      return;
    }

    if (cu_msg == NULL) {
      return;
    }

    cu_msg->seq = (nx_uint16_t) configuration_seq;
//    cu_msg->vnet_id = (nx_uint16_t) 0;
    //cu_msg->vnet_id = (nx_uint16_t) call ConfigurationCache.get_virtual_network_id();
    cu_msg->conf_id = (nx_uint8_t) configuration_id;

    // get crc of the FFControl and address
    cu_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq,
    				sizeof(nx_struct FFControl) - sizeof(cu_msg->crc));

    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_SEND_CONTROL_MSG, configuration_seq, configuration_id);

    printf("CU sending\n");
    printfflush();

    if (call NetworkAMSend.send(AM_BROADCAST_ADDR, &confmsg, sizeof(nx_struct FFControl)) != SUCCESS) {
      call Timer.startOneShot(call Random.rand16() % POLICY_RAND_SEND);
    }
    same_msg_counter = 0;

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
