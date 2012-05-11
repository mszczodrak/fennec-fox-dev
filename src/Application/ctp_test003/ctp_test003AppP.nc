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
#include "ctp_test003App.h"
#include <Timer.h>


generic module ctp_test003AppP(uint16_t delay, uint16_t src, uint16_t dest) {
  provides interface Mgmt;
  provides interface Module;

  uses interface Leds;
  uses interface Timer<TMilli>;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {

  message_t packet;
  bool sendBusy = FALSE;
  uint16_t seqno;

  command error_t Mgmt.start() {
    seqno = 0;
    if ((src == NODE) || (src == TOS_NODE_ID)) {
      call Timer.startPeriodic(delay * 1024U);
    }

//    dbg("Application", "Application CTP_test start\n");
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
//    dbg("Application", "Application CTP_test stop\n");

    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  void sendMessage() {
    TestNetworkMsg* msg = (TestNetworkMsg*)call NetworkAMSend.getPayload(&packet, sizeof(TestNetworkMsg));

    if (msg == NULL) {
      dbg("Application", "Application CTP_test msg == NULL\n");
      return;
    }

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;

    dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, 0);

    if (call NetworkAMSend.send(dest, &packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      dbg("Application", "Application CTP_test send message FAIL\n");
    }
    else {
      dbg("Application", "Application CTP_test send message SUCCESS\n");
      sendBusy = TRUE;
      call Leds.set(seqno);
      seqno++;
    }
  }

  event void Timer.fired() {
    if (!sendBusy) {
      sendMessage();
    }
  }

  event void NetworkAMSend.sendDone(message_t* m, error_t err) {
    //dbg("Application", "Application CTP_test NetworkAMSend.sendDone\n");
    sendBusy = FALSE;
  }

  event message_t*  NetworkReceive.receive(message_t* msg, void* payload, uint8_t len) {
    TestNetworkMsg* m = (TestNetworkMsg*)payload;
    dbg("Application", "Application CTP_test NetworkReceive.receive\n");
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, m->seqno, m->source);
    call Leds.set(m->seqno);
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }

}
