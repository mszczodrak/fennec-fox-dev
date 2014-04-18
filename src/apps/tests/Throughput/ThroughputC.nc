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
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
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

#include "Throughput.h"

generic configuration ThroughputC(process_t process) {
provides interface SplitControl;
provides interface Module;

uses interface ThroughputParams;
   
uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface ModuleStatus as SubStatus;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

}

implementation {
 
enum {
	SERIAL_PORT = 1
};
 
components new ThroughputP(process);
SplitControl = ThroughputP;
Module = ThroughputP;
ThroughputParams = ThroughputP;
  
components new TimerMilliC() as TimerImp;
ThroughputP.Timer -> TimerImp;

/* Creating a queue for sending messages over the network interface */
components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as SubQueueC;
ThroughputP.SubQueue -> SubQueueC;

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
/* Creating a queue for sending messages over the serial interface */
components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
ThroughputP.SerialQueue -> SerialQueueC;
#endif

/* Creating a pool of message memory for network and serial communication */
components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
ThroughputP.MessagePool -> MessagePoolC;

components LedsC;
ThroughputP.Leds -> LedsC;

#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
components SerialActiveMessageC;
components new SerialAMSenderC(SERIAL_PORT);
components new SerialAMReceiverC(SERIAL_PORT);
ThroughputP.SerialAMSend -> SerialAMSenderC.AMSend;
ThroughputP.SerialAMPacket -> SerialAMSenderC.AMPacket;
ThroughputP.SerialPacket -> SerialAMSenderC.Packet; 
ThroughputP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
ThroughputP.SerialReceive -> SerialAMReceiverC.Receive;
#endif
 
SubAMSend = ThroughputP.SubAMSend;
SubReceive = ThroughputP.SubReceive;
SubSnoop = ThroughputP.SubSnoop;
SubAMPacket = ThroughputP.SubAMPacket;
SubPacket = ThroughputP.SubPacket;
SubPacketAcknowledgements = ThroughputP.SubPacketAcknowledgements;
SubStatus = ThroughputP.SubStatus;

SubPacketLinkQuality = ThroughputP.SubPacketLinkQuality;
SubPacketTransmitPower = ThroughputP.SubPacketTransmitPower;
SubPacketRSSI = ThroughputP.SubPacketRSSI;

}

