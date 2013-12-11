/*
 *  Throughput Test Application module for Fennec Fox platform.
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
 * Application: Throughput Test Application Module
 * Author: Marcin Szczodrak
 * Date: 1/21/2013
 * Last Modified: 1/21/2013
 */

#include "ThroughputApp.h"

configuration ThroughputAppC {
  provides interface SplitControl;
  provides interface Module;

  uses interface ThroughputAppParams;
   
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
 
components ThroughputAppP;
SplitControl = ThroughputAppP;
Module = ThroughputAppP;
ThroughputAppParams = ThroughputAppP;
  
components new TimerMilliC() as TimerImp;
ThroughputAppP.Timer -> TimerImp;

/* Creating a queue for sending messages over the network interface */
components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
ThroughputAppP.NetworkQueue -> NetworkQueueC;

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
/* Creating a queue for sending messages over the serial interface */
components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
ThroughputAppP.SerialQueue -> SerialQueueC;
#endif

/* Creating a pool of message memory for network and serial communication */
components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
ThroughputAppP.MessagePool -> MessagePoolC;

components LedsC;
ThroughputAppP.Leds -> LedsC;

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
components SerialActiveMessageC;
components new SerialAMSenderC(SERIAL_PORT);
components new SerialAMReceiverC(SERIAL_PORT);
ThroughputAppP.SerialAMSend -> SerialAMSenderC.AMSend;
ThroughputAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
ThroughputAppP.SerialPacket -> SerialAMSenderC.Packet; 
ThroughputAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
ThroughputAppP.SerialReceive -> SerialAMReceiverC.Receive;
#endif
 
NetworkAMSend = ThroughputAppP.NetworkAMSend;
NetworkReceive = ThroughputAppP.NetworkReceive;
NetworkSnoop = ThroughputAppP.NetworkSnoop;
NetworkAMPacket = ThroughputAppP.NetworkAMPacket;
NetworkPacket = ThroughputAppP.NetworkPacket;
NetworkPacketAcknowledgements = ThroughputAppP.NetworkPacketAcknowledgements;
NetworkStatus = ThroughputAppP.NetworkStatus;

}

