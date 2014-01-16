/*
 *  PIR Sensor Test application module for Fennec Fox platform.
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
 * Network: PIR Sensor Test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <ff_sensors.h>
#include "PIRApp.h"

generic module PIRAppP(uint16_t delay) {
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
  uses interface Timer<TMilli> as Timer;

  uses interface Read<struct ff_sensor_pir> as PIR;
}

implementation {

  command error_t Mgmt.start() {
    dbg("Application", "Application PIR starts\n");
    call Timer.startPeriodic(delay);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbg("Application", "Application PIR stops\n");
    call Timer.stop();
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer.fired() {
    if (call PIR.read() != SUCCESS) {
      printf("Presence: Sensor Reading Error - Failed To Read\n");
    }
  }

  event void PIR.readDone( error_t result, struct ff_sensor_pir val ) {
    if (result == SUCCESS) {
      printf("Presence: %d\n", val.presence);
      printfflush();	
    } else {
      printf("Presence: Sensor Reading Error\n");
    }
  }


  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }
}
