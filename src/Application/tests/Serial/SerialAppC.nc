/*
 *  Serial Test Application module for Fennec Fox platform.
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
 * Application: Serial Test Application Module
 * Author: Marcin Szczodrak
 * Date: 1/21/2013
 * Last Modified: 1/21/2013
 */

#include "SerialApp.h"

configuration SerialAppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface SerialAppParams;
   
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {
 
  enum {
    SERIAL_PORT = 1
  };
 
  components SerialAppP;
  Mgmt = SerialAppP;
  Module = SerialAppP;
  SerialAppParams = SerialAppP;
  
  components new TimerMilliC() as TimerImp;
  SerialAppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  SerialAppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network and serial communication */
  components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
  SerialAppP.MessagePool -> MessagePoolC;

  components LedsC;
  SerialAppP.Leds -> LedsC;

  components SerialActiveMessageC;
  components new SerialAMSenderC(SERIAL_PORT);
  components new SerialAMReceiverC(SERIAL_PORT);
  SerialAppP.SerialAMSend -> SerialAMSenderC.AMSend;
  SerialAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  SerialAppP.SerialPacket -> SerialAMSenderC.Packet; 
  SerialAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  SerialAppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  NetworkAMSend = SerialAppP.NetworkAMSend;
  NetworkReceive = SerialAppP.NetworkReceive;
  NetworkSnoop = SerialAppP.NetworkSnoop;
  NetworkAMPacket = SerialAppP.NetworkAMPacket;
  NetworkPacket = SerialAppP.NetworkPacket;
  NetworkPacketAcknowledgements = SerialAppP.NetworkPacketAcknowledgements;
  NetworkStatus = SerialAppP.NetworkStatus;

}

