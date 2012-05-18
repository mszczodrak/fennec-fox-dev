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
#include "CounterApp.h"

generic module CounterAppP(uint16_t init_delay_ms, uint16_t delay_ms, uint16_t delay_scale, uint16_t src, uint16_t dest, uint16_t max_sequence) {
  provides interface Mgmt;

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
    dbg("Application", "Application: Counter start\n");
    //dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }


  command error_t Mgmt.stop() {
    call Timer.stop();

    if (call ExperimentTimer.isRunning()) {
      signal ExperimentTimer.fired();
    }

    dbg("Application", "Application: Counter stop\n");
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

    dbg("Application", "Application Counter sends %d %d\n", msg->seqno, msg->source); 
    dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, 0);

    if (call NetworkAMSend.send(dest, &packet, sizeof(CounterMsg)) != SUCCESS) {
    }
    else {
      sendBusy = TRUE;
      //call Leds.set(seqno);
    }
  }


  event void Timer.fired() {
    uint32_t delay = (uint32_t)delay_ms * (uint32_t)delay_scale;
    if (!sendBusy) {
      sendMessage();
    }

    seqno++;

    if (seqno < max_sequence) {
      call Timer.startOneShot(delay);
    } else {
      call ExperimentTimer.startOneShot(delay);
    }
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    if (error == SUCCESS) {
      CounterMsg* cm = (CounterMsg*)call NetworkAMSend.getPayload(msg, sizeof(CounterMsg));
      sender_check[cm->seqno] = 1;
    }
    sendBusy = FALSE;
  }


  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    CounterMsg* cm = (CounterMsg*)payload;
    receiver_check[cm->seqno] = 1;

    dbg("Application", "Application Counter receive %d %d\n", cm->seqno, cm->source); 
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source);
    call ExperimentTimer.startOneShot(10000);
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
      //dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, max_sequence, ok);
    }

    if (dest == TOS_NODE_ID) {
      for(i = 0; i < max_sequence; i++) {
         ok +=receiver_check[i];
      }
      //dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, max_sequence, ok);
    }
  }

}
