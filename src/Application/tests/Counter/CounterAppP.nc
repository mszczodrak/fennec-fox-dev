/*
 *  Counter test application module for Fennec Fox platform.
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
 * Network: Counter test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <Timer.h>
#include "CounterApp.h"

module CounterAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface CounterAppParams;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface Leds;
  uses interface Timer<TMilli>;

  uses interface PacketTimeStamp<TMilli,uint32_t>;
}

implementation {

  message_t packet;
  bool sendBusy = FALSE;
  uint16_t seqno;

  command error_t Mgmt.start() {
    uint32_t send_delay = call CounterAppParams.get_delay() * 
		call CounterAppParams.get_delay_scale();
    seqno = 0;

    if ((call CounterAppParams.get_src() == NODE) || 
	(call CounterAppParams.get_src() == TOS_NODE_ID)) {
      call Timer.startPeriodic(send_delay);
    }
    dbg("Application", "Application: Counter start\n");
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }


  command error_t Mgmt.stop() {
    call Timer.stop();
    dbg("Application", "Application: Counter stop\n");
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }


  void sendMessage() {
    CounterMsg* msg = (CounterMsg*)call NetworkAMSend.getPayload(&packet,
							sizeof(CounterMsg));

    if (msg == NULL) {
      return;
    }

    msg->source = TOS_NODE_ID;
    msg->seqno = seqno;

    dbg("Application", "Application Counter sends %d %d\n", msg->seqno,
								msg->source); 
    dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, 0);

    if (call NetworkAMSend.send(call CounterAppParams.get_dest(), &packet, 
					sizeof(CounterMsg)) != SUCCESS) {
    }
    else {
      sendBusy = TRUE;
      call Leds.set(seqno);
    }
  }


  event void Timer.fired() {
    if (!sendBusy) {
      sendMessage();
    }

    seqno++;
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    sendBusy = FALSE;
  }


  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    uint32_t rxTimestamp = call PacketTimeStamp.timestamp(msg);
    uint16_t *t1 = (uint16_t*) &rxTimestamp;
    uint16_t *t2 = ++t1;
    CounterMsg* cm = (CounterMsg*)payload;

    dbg("Application", "Application Counter receive %d %d\n", cm->seqno, cm->source); 
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source);
    dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, *t1, *t2);
    call Leds.set(cm->seqno);
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }

  event void CounterAppParams.receive_status(uint16_t status_flag) {
  }

}
