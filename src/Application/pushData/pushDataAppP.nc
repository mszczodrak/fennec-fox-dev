/*
 *  Dummy application module for Fennec Fox platform.
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
 * Network: Dummy Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <Timer.h>
#include "pushDataApp.h"

generic module pushDataAppP(uint32_t init_delay_ms, uint16_t delay_ms, uint16_t src, uint16_t dest, uint16_t max_sequence) {
  provides interface Mgmt;
  provides interface Module;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface Leds;
  uses interface Timer<TMilli>;
  uses interface Timer<TMilli> as ExperimentTimer;
}

implementation {


  message_t packet;
  bool sendBusy = FALSE;
  uint16_t seqno;
  bool receiver_check[max_sequence];
  bool sender_check[max_sequence];

  command error_t Mgmt.start() {
    uint16_t i;
    for(i = 0; i < max_sequence; i++) {
      receiver_check[i] = 0;
      sender_check[i] = 0;
    }

    seqno = 0;

    if ((src == NODE) || (src == TOS_NODE_ID)) {
      call Timer.startOneShot(init_delay_ms);
    }

    //dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }


  command error_t Mgmt.stop() {
    call Timer.stop();
    //dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }


  void sendMessage() {
    CounterMsg* msg = (CounterMsg*)call NetworkAMSend.getPayload(&packet, sizeof(CounterMsg));

    if (msg == NULL) {
      return;
    }

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;

    dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, 0);

    if (call NetworkAMSend.send(dest, &packet, sizeof(CounterMsg)) != SUCCESS) {
      call Timer.startOneShot(delay_ms);
    } else {
      sendBusy = TRUE;
      call Leds.set(seqno);
    }
  }


  event void Timer.fired() {
    if (!sendBusy) {
      if (seqno < max_sequence) {
        sendMessage();
      }
    }

    if (seqno < max_sequence) {
      call Timer.startOneShot(10 * delay_ms);
    } else {
      call ExperimentTimer.startOneShot(30000);
    }
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    if (error == SUCCESS) {
      CounterMsg* cm = (CounterMsg*)call NetworkAMSend.getPayload(msg, sizeof(CounterMsg));
      sender_check[cm->seqno] = 1;
      seqno++;
    }
    atomic {
      sendBusy = FALSE;
      signal Timer.fired();
    }
  }


  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    CounterMsg* cm = (CounterMsg*)payload;
    receiver_check[cm->seqno] = 1;
 
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source);
    call ExperimentTimer.startOneShot(30000);
    call Leds.set(cm->seqno);
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }

  event void ExperimentTimer.fired() {
    uint16_t ok = 0;
    uint16_t i = 0;

    if (src == TOS_NODE_ID) {
      for(i = 0; i < max_sequence; i++) {
         ok +=sender_check[i];
      }
      dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, max_sequence, ok);
    }

    if (dest == TOS_NODE_ID) {
      for(i = 0; i < max_sequence; i++) {
         ok +=receiver_check[i];
      }
      dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, max_sequence, ok);
    }
  }

}
