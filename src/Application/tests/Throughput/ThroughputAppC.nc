/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Throughput Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include "ThroughputApp.h"

generic configuration ThroughputAppC() {
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
 
components new ThroughputAppP();
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

