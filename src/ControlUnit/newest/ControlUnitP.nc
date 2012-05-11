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
#define POLICY_RESEND_RECONF	2
#define POLICY_MAX_WRONG_CONFS	5

#define POLICY_RAND_MOD 	10
#define POLICY_RAND_OFFSET	1
#define POLICY_RAND_SEND	0
#define SAME_MSG_COUNTER_THRESHOLD 1

module ControlUnitP {
  provides interface SimpleStart;

  uses interface AMSend as MacAMSend;
  uses interface Receive as MacReceive;
  uses interface Receive as MacSnoop;
  uses interface AMPacket as MacAMPacket;
  uses interface Packet as MacPacket;
  uses interface PacketAcknowledgements as MacPacketAcknowledgements;
  uses interface ModuleStatus as MacStatus;

  uses interface Mgmt as FennecEngine;

  uses interface EventCache;
  uses interface PolicyCache;

  uses interface Random;
  uses interface Timer<TMilli> as Timer;
}

implementation {

  uint8_t configuration_id;
  uint16_t configuration_seq;
  uint8_t same_msg_counter;

  uint8_t resend_confs;

  message_t confmsg;

  task void sendConfigurationMsg();
  task void start_engine();
  task void stop_engine();

  void start_policy_send() {
    uint16_t send_delay = POLICY_RAND_SEND;
    if (send_delay) {
      call Timer.startOneShot(call Random.rand16() % send_delay);
    } else {
      dbg("ControlUnit", "ControlUnit Timer.fired()\n");
      post sendConfigurationMsg();
    }
  }

  void set_new_state(uint8_t conf, uint8_t seq) {
    call Timer.stop();
    dbg("ControlUnit", "ControlUnit: new state id %d with sequence %d\n", conf, seq);
    //printf("Set new state %d %d\n", conf, seq);
    atomic {
      configuration_id = conf;
      configuration_seq = seq;
      post stop_engine();
    }
  }

  command void SimpleStart.start() {
    dbg("ControlUnit", "ControlUnit: simple start\n");
    set_new_state(get_state_id(), CONFIGURATION_SEQ_UNKNOWN);
    signal SimpleStart.startDone(SUCCESS);
  }

  event void PolicyCache.newConf(uint8_t new_conf) {
    dbg("ControlUnit", "ControlUnit: newConf %d\n", new_conf);
    //printf("Policy New conf %d\n", new_conf);
    set_new_state(new_conf, configuration_seq + 1);
  }

  event void PolicyCache.wrong_conf() {}

  event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {

    nx_struct FFControl *cu_msg = (nx_struct FFControl*) payload;

    dbg("ControlUnit", "ControlUnit: receive message\n");

    if (cu_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq, 
						len - sizeof(cu_msg->crc))) {
      goto done_receive;
    }

    //dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);

    if (!call PolicyCache.valid_policy_msg(cu_msg)) {
      goto done_receive;
    }

    // First time receives Configuration
    if ( configuration_seq == CONFIGURATION_SEQ_UNKNOWN && cu_msg->seq != CONFIGURATION_SEQ_UNKNOWN ) {
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_FIRST_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);
      goto reconfigure;
    } 

    /* Received configuration message with unknown sequence */
    if ( cu_msg->seq == CONFIGURATION_SEQ_UNKNOWN && configuration_seq != CONFIGURATION_SEQ_UNKNOWN ) {
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_UNKNOWN_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);
      goto reset;
    }

    /* Received configuration message with lower sequence */
    if (cu_msg->seq < configuration_seq) {
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_LOWER_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);
      goto reset;
    }

    /* Received configuration message with the same sequence number */
    if (cu_msg->seq == configuration_seq) {
      
      if (cu_msg->conf_id == configuration_id) {
        /* Received same sequence with the same configuration id */
//        if (call Timer.isRunning()) {
	  same_msg_counter++;
//	}
        goto done_receive;
      }

      /* there is an inconsistency in a network */
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);
      configuration_seq += (call Random.rand16() % POLICY_RAND_MOD) + POLICY_RAND_OFFSET;
      goto reset;
    }

    /* Received configuration message with larger sequence number */
    if (cu_msg->seq > configuration_seq) {
      dbgs(F_CONTROL_UNIT, S_NONE, DBGS_RECEIVE_HIGHER_CONTROL_MSG, cu_msg->seq, cu_msg->conf_id);
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
    dbg("ControlUnit", "ControlUnit: reconfigure\n");
    if ((cu_msg->conf_id != configuration_id) && 
	(cu_msg->conf_id < call PolicyCache.get_number_of_configurations())
                                			) {
      set_new_state(cu_msg->conf_id, cu_msg->seq);
    }

done_receive:
    return msg;
  }

  event void MacAMSend.sendDone(message_t *msg, error_t error) {
    dbg("ControlUnit", "ControlUnit: sendDone error=%d\n", error);
    same_msg_counter = 0;
    if (error != SUCCESS) {
      start_policy_send();
    } else {
      resend_confs--;
      if (resend_confs > 0) {
        start_policy_send();
      }
    }
  }

  event void Timer.fired() {
    dbg("ControlUnit", "ControlUnit Timer.fired()\n");
    post sendConfigurationMsg();
  }


  event void FennecEngine.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("ControlUnit", "ControlUnit FennecEngine startDone SUCCESS\n");
      resend_confs = POLICY_RESEND_RECONF; 
      same_msg_counter = 0;
      start_policy_send();
    } else {
      dbg("ControlUnit", "ControlUnit FennecEngine startDone FAIL - retry\n");
      call FennecEngine.start();
    }
  }

  event void FennecEngine.stopDone(error_t err) {
    if (err == SUCCESS) {
      dbg("ControlUnit", "ControlUnit FennecEngine stopDone SUCCESS\n");
      //printf("Engine stop done\n");
      post start_engine();
    } else {
       dbg("ControlUnit", "ControlUnit FennecEngine stopDone DAIL - retry\n");
      //printf("Retry to start engine\n");
      call FennecEngine.stop();
    }
  }


  task void start_engine() {
    //call EventCache.clearMask();
    call PolicyCache.control_unit_support(1);
    call PolicyCache.set_active_configuration(configuration_id);
    call FennecEngine.start();
  }

  task void stop_engine() {
    call EventCache.clearMask();
    //call PolicyCache.control_unit_support(1);
    call FennecEngine.stop();
  }


  task void sendConfigurationMsg() {

    nx_struct FFControl *cu_msg;

    if (call PolicyCache.get_number_of_configurations() == 1) {
      return;
    }

    cu_msg = (nx_struct FFControl*) call MacAMSend.getPayload(&confmsg, sizeof(nx_struct FFControl));

    if (same_msg_counter > SAME_MSG_COUNTER_THRESHOLD) {
      dbg("ControlUnit", "ControlUnit sendConfigurationMsg() does not happen, same_msg_counter is %d\n", same_msg_counter);
      return;
    } else {
      dbg("ControlUnit", "ControlUnit sendConfigurationMsg()\n");
    }

    if (cu_msg == NULL) {
      return;
    }

    cu_msg->seq = (nx_uint16_t) configuration_seq;
    cu_msg->vnet_id = 0;
    cu_msg->conf_id = (nx_uint8_t) configuration_id;

    // get crc of the FFControl and address
    cu_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*)&cu_msg->seq,
    				sizeof(nx_struct FFControl) - sizeof(cu_msg->crc));

    dbgs(F_CONTROL_UNIT, S_NONE, DBGS_SEND_CONTROL_MSG, configuration_seq, configuration_id);

    if (call MacAMSend.send(AM_BROADCAST_ADDR, &confmsg, sizeof(nx_struct FFControl)) != SUCCESS) {
      start_policy_send();
    }
    same_msg_counter = 0;

  }

  event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void MacStatus.status(uint8_t layer, uint8_t status_flag) {
  }

}


