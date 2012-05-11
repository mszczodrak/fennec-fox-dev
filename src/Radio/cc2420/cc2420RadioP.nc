/*
 *  Dummy radio module for Fennec Fox platform.
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
 * Network: Dummy Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "cc2420Radio.h"

generic module cc2420RadioP(am_addr_t sink_addr, uint8_t channel, uint8_t power,
                                uint16_t remote_wakeup, uint16_t delay_after_receive,
                                uint16_t backoff, uint16_t min_backoff, uint8_t ack, 
				uint8_t cca, uint8_t crc) @safe() {

  provides interface Mgmt;
  provides interface ModuleStatus as RadioStatus;
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;


  uses interface SplitControl as RadioControl;
  uses interface ParametersCC2420;

  uses interface AMSend;
  uses interface Receive;
  uses interface Receive as Snoop;
  uses interface AMPacket;
}

implementation {

  uint8_t status = S_STOPPED;

  command error_t Mgmt.start() {
    if (status == S_STARTED) {
      dbg("Radio", "Radio cc2420 already started\n");
      signal Mgmt.startDone(SUCCESS);
      return SUCCESS;
    }

    call ParametersCC2420.set_sink_addr(sink_addr);
    call ParametersCC2420.set_channel(channel);
    call ParametersCC2420.set_power(power);
    call ParametersCC2420.set_remote_wakeup(remote_wakeup);
    call ParametersCC2420.set_delay_after_receive(delay_after_receive);
    call ParametersCC2420.set_backoff(backoff);
    call ParametersCC2420.set_min_backoff(min_backoff);
    call ParametersCC2420.set_ack(ack);
    call ParametersCC2420.set_cca(cca);
    call ParametersCC2420.set_crc(crc);

    dbg("Radio", "Radio cc2420 starts\n");

    if (call RadioControl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
    }
    status = S_STARTING;
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    if (status == S_STOPPED) {
      dbg("Radio", "Radio cc2420 already stopped\n");
      signal Mgmt.stopDone(SUCCESS);
      return SUCCESS;
    }

    dbg("Radio", "Radio cc2420 stops\n");

    if (call RadioControl.stop() != SUCCESS) {
      signal Mgmt.stopDone(FAIL);
    }
    status = S_STOPPING;
    return SUCCESS;
  }


  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    } else {
      if (status == S_STARTING) {
        dbg("Radio", "Radio cc2420 got RadioControl startDone\n");
        status = S_STARTED;
        signal RadioStatus.status(F_RADIO, ON);
        signal Mgmt.startDone(SUCCESS);
      }
    }
  }


  event void RadioControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.stop();
    } else {
      if (status == S_STOPPING) {
        dbg("Radio", "Radio cc2420 got RadioControl stopDone\n");
        status = S_STOPPED;
        signal RadioStatus.status(F_RADIO, OFF);
        signal Mgmt.stopDone(SUCCESS);
      }
    }
  }

  command error_t RadioAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    call AMPacket.setGroup(msg, msg->conf);
    dbg("Radio", "Radio sends msg on state %d\n", msg->conf);
    return call AMSend.send(addr, msg, len);
  }

  command error_t RadioAMSend.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t RadioAMSend.maxPayloadLength() {
    return call AMSend.maxPayloadLength();
  }

  command void* RadioAMSend.getPayload(message_t* msg, uint8_t len) {
    return call AMSend.getPayload(msg, len);
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
    signal RadioAMSend.sendDone(msg, error);
  }


  event message_t* Receive.receive(message_t *msg, void* payload, uint8_t len) {
    msg->conf = call AMPacket.group(msg);
    dbg("Radio", "Radio receives msg on state %d\n", msg->conf);
    return signal RadioReceive.receive(msg, payload, len);
  }

  event message_t* Snoop.receive(message_t *msg, void* payload, uint8_t len) {
    msg->conf = call AMPacket.group(msg);
    return signal RadioSnoop.receive(msg, payload, len);
  }

}

