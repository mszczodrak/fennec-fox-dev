/*
 * Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Ctp.h"

/**
 * A data collection service that uses a tree routing protocol
 * to deliver data to collection roots, following TEP 119.
 *
 * @author Rodrigo Fonseca
 * @author Omprakash Gnawali
 * @author Kyle Jamieson
 * @author Philip Levis
 */


generic configuration CtpP() {
provides interface StdControl;
provides interface Send[uint8_t client];
provides interface Receive[collection_id_t id];
provides interface Receive as Snoop[collection_id_t];
provides interface Intercept[collection_id_t id];

provides interface Packet;
provides interface AMPacket;
provides interface CollectionPacket;
provides interface CtpPacket;

provides interface CtpInfo;
provides interface LinkEstimator;
provides interface CtpCongestion;
provides interface RootControl;    

provides interface PacketAcknowledgements;

uses interface CollectionId[uint8_t client];
uses interface CollectionDebug;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_CTP_CLIENT),
    FORWARD_COUNT = 12,
    TREE_ROUTING_TABLE_SIZE = 10,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
    CACHE_SIZE = 4,
  };

enum {
	NUM_CLIENTS = uniqueCount(UQ_AMQUEUE_SEND)
};


components new CtpActiveMessageC();
components new CtpForwardingEngineP() as Forwarder;
components LedsC;
  
Send = Forwarder;
StdControl = Forwarder;
Receive = Forwarder.Receive;
Snoop = Forwarder.Snoop;
Intercept = Forwarder;
Packet = Forwarder;
AMPacket = Forwarder;
CollectionId = Forwarder;
CollectionPacket = Forwarder;
CtpPacket = Forwarder;
CtpCongestion = Forwarder;
  
Forwarder.Leds -> LedsC;

PacketAcknowledgements = CtpActiveMessageC.PacketAcknowledgements;
MacAMSend = CtpActiveMessageC;
MacReceive = CtpActiveMessageC.MacReceive;
MacSnoop = CtpActiveMessageC.MacSnoop;
MacAMPacket = CtpActiveMessageC.MacAMPacket;
MacPacket = CtpActiveMessageC.MacPacket;
MacPacketAcknowledgements = CtpActiveMessageC.MacPacketAcknowledgements;

components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
Forwarder.QEntryPool -> QEntryPoolP;
Forwarder.MessagePool -> MessagePoolP;

components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
Forwarder.SendQueue -> SendQueueP;

components MainC, new LruCtpMsgCacheP(CACHE_SIZE) as CacheP;
StdControl = CacheP;
Forwarder.SentCache -> CacheP;
CacheP.CtpPacket -> Forwarder;
MainC.SoftwareInit -> CacheP;

components new TimerMilliC() as RoutingBeaconTimer;
components new TimerMilliC() as RouteUpdateTimer;
components LinkEstimatorP as Estimator;
Forwarder.LinkEstimator -> Estimator;

components new CtpRoutingEngineP(TREE_ROUTING_TABLE_SIZE, 128, 512000) as Router;

components new CtpAMQueueEntryP(AM_CTP_DATA) as AMSenderC;
AMSenderC.AMPacket -> CtpActiveMessageC;
AMSenderC.Send -> CtpAMQueueImplP.Send[unique(UQ_AMQUEUE_SEND)];

components new CtpAMQueueEntryP(AM_CTP_ROUTING) as SendControl;
SendControl.AMPacket -> CtpActiveMessageC;
SendControl.Send -> CtpAMQueueImplP.Send[unique(UQ_AMQUEUE_SEND)];

components new CtpAMQueueImplP(NUM_CLIENTS);
CtpAMQueueImplP.AMSend -> CtpActiveMessageC;
CtpAMQueueImplP.AMPacket -> CtpActiveMessageC;
CtpAMQueueImplP.Packet -> CtpActiveMessageC;

StdControl = Router;
StdControl = Estimator;
RootControl = Router;
Router.BeaconSend -> Estimator.Send;
Router.BeaconReceive -> Estimator.Receive;
Router.LinkEstimator -> Estimator.LinkEstimator;

Router.CompareBit -> Estimator.CompareBit;

Router.AMPacket -> CtpActiveMessageC;
Router.BeaconTimer -> RoutingBeaconTimer;
Router.RouteTimer -> RouteUpdateTimer;
Router.CollectionDebug = CollectionDebug;
Forwarder.CollectionDebug = CollectionDebug;
Forwarder.CtpInfo -> Router;
Router.CtpCongestion -> Forwarder;
CtpInfo = Router;

components new TimerMilliC() as RetxmitTimer;
Forwarder.RetxmitTimer -> RetxmitTimer;

components RandomC;
Router.Random -> RandomC;
Forwarder.Random -> RandomC;

Forwarder.SubSend -> AMSenderC;
Forwarder.SubReceive -> CtpActiveMessageC.Receive[AM_CTP_DATA]; //AMReceiverC;  
Forwarder.SubSnoop -> CtpActiveMessageC.Snoop[AM_CTP_DATA]; //AMSnooperC;

Forwarder.SubPacket -> CtpActiveMessageC;
Forwarder.RootControl -> Router;
Forwarder.UnicastNameFreeRouting -> Router.Routing;
Forwarder.PacketAcknowledgements -> CtpActiveMessageC;
Forwarder.SubAMPacket -> CtpActiveMessageC;

LinkEstimator = Estimator;
  
Estimator.Random -> RandomC;

Estimator.AMSend -> SendControl;
Estimator.SubReceive -> CtpActiveMessageC.Receive[AM_CTP_ROUTING]; //ReceiveControl;

Estimator.SubPacket -> CtpActiveMessageC;
Estimator.SubAMPacket -> CtpActiveMessageC;

MacLinkPacketMetadata = Estimator.MacLinkPacketMetadata;

}
