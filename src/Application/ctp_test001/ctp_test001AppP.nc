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
#include "ctp_test001App.h"
#include "Timer.h"
#include "TestNetwork.h"
#include "CtpDebugMsg.h"
#include <Timer.h>


generic module ctp_test001AppP(uint16_t src, uint16_t dest) {

  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;


  uses interface SplitControl as RadioControl;
  uses interface StdControl as RoutingControl;
  uses interface StdControl as DisseminationControl;
  uses interface DisseminationValue<uint32_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface CollectionPacket;
  uses interface CtpInfo;
  uses interface CtpCongestion;
  uses interface Random;
  uses interface CollectionDebug;
  uses interface AMPacket;
  uses interface Packet as RadioPacket;
  uses interface LowPowerListening;
}

implementation {

  command error_t Mgmt.start() {
    if (TOS_NODE_ID == dest) {
      call LowPowerListening.setLocalWakeupInterval(0);
    }
    call RadioControl.start();

    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {

    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    signal Module.drop_message(msg);
  }

  message_t packet;
  uint8_t msglen;
  bool sendBusy = FALSE;
  bool firstTimer = TRUE;
  uint16_t seqno;
  enum {
    SEND_INTERVAL = 10*1024U,
  };

  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      //call DisseminationControl.start();
      call RoutingControl.start();
      if (TOS_NODE_ID == dest) {
        call RootControl.setRoot();
      }
      seqno = 0;
      call Timer.startOneShot(call Random.rand32() % SEND_INTERVAL);
    }
  }


  event void RadioControl.stopDone(error_t err) {}


  void sendMessage() {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet, sizeof(TestNetworkMsg));

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;

    dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, 0);

    if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
    }
    else {
      sendBusy = TRUE;
      call Leds.set(seqno);
      seqno++;
    }
  }

  event void Timer.fired() {
    uint32_t nextInt;
    nextInt = call Random.rand32() % SEND_INTERVAL;
    nextInt += SEND_INTERVAL >> 1;
    call Timer.startOneShot(nextInt);
    if (!sendBusy)
        sendMessage();
  }

  event void Send.sendDone(message_t* m, error_t err) {
    sendBusy = FALSE;
  }

  event void DisseminationPeriod.changed() {
    const uint32_t* newVal = call DisseminationPeriod.get();
    call Timer.stop();
    call Timer.startPeriodic(*newVal);
  }

  event message_t*
  Receive.receive(message_t* msg, void* payload, uint8_t len) {
    TestNetworkMsg* m = (TestNetworkMsg*)payload;
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, m->seqno, m->source);
    call Leds.set(m->seqno);

    return msg;
 }


}
