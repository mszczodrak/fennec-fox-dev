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


configuration CtpP {
  provides {
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t];
    interface Intercept[collection_id_t id];

    interface Packet;
    interface CollectionPacket;
    interface CtpPacket;

    interface CtpInfo;
    interface LinkEstimator;
    interface CtpCongestion;
    interface RootControl;
    interface UnicastNameFreeRouting;
  }

  uses {
    interface CollectionId[uint8_t client];
    interface CollectionDebug;
  }

uses interface SplitControl as RadioControl;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface AMSend as SubAMSend;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;

}

implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_CTP_CLIENT),
    FORWARD_COUNT = 12,
    TREE_ROUTING_TABLE_SIZE = 10,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
    CACHE_SIZE = 4,
  };

  components new CtpForwardingEngineP() as Forwarder;
  components MainC, LedsC;
  
  Send = Forwarder;
  StdControl = Forwarder;
  Receive = Forwarder.Receive;
  Snoop = Forwarder.Snoop;
  Intercept = Forwarder;
  Packet = Forwarder;
  CollectionId = Forwarder;
  CollectionPacket = Forwarder;
  CtpPacket = Forwarder;
  CtpCongestion = Forwarder;
  
  components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
  components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
  Forwarder.QEntryPool -> QEntryPoolP;
  Forwarder.MessagePool -> MessagePoolP;

  components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
  Forwarder.SendQueue -> SendQueueP;

  components new LruCtpMsgCacheC(CACHE_SIZE) as SentCacheP;
  Forwarder.SentCache -> SentCacheP;

  components new TimerMilliC() as RoutingBeaconTimer;
  components new TimerMilliC() as RouteUpdateTimer;
  components LinkEstimatorP as Estimator;
  Forwarder.LinkEstimator -> Estimator;

  components new CtpRoutingEngineP(TREE_ROUTING_TABLE_SIZE, 128, 512000) as Router;

  StdControl = Router;
  StdControl = Estimator;
  RootControl = Router;
  UnicastNameFreeRouting = Router;

  MainC.SoftwareInit -> Router;
  Router.BeaconSend -> Estimator.Send;
  Router.BeaconReceive -> Estimator.Receive;
  Router.LinkEstimator -> Estimator.LinkEstimator;

  Router.CompareBit -> Estimator.CompareBit;


SubAMPacket = Router.AMPacket;
RadioControl = Router.RadioControl;
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

  MainC.SoftwareInit -> Forwarder;
  Forwarder.SubSend -> CtpMultiplexC.AMSend[AM_CTP_DATA];
  Forwarder.SubReceive -> CtpMultiplexC.Receive[AM_CTP_DATA];
  Forwarder.SubSnoop -> CtpMultiplexC.Snoop[AM_CTP_DATA];
SubPacket = Forwarder.SubPacket;
  Forwarder.RootControl -> Router;
  Forwarder.UnicastNameFreeRouting -> Router.Routing;
RadioControl = Forwarder.RadioControl;
SubPacketAcknowledgements = Forwarder.PacketAcknowledgements;
SubAMPacket = Forwarder.AMPacket;
  Forwarder.Leds -> LedsC;
  
  LinkEstimator = Estimator;
  
  Estimator.Random -> RandomC;

  Estimator.AMSend -> CtpMultiplexC.AMSend[AM_CTP_ROUTING];
  Estimator.SubReceive -> CtpMultiplexC.Receive[AM_CTP_ROUTING];
SubPacket = Estimator.SubPacket;
SubAMPacket = Estimator.SubAMPacket;

SubLinkPacketMetadata = Estimator.LinkPacketMetadata;

  MainC.SoftwareInit -> Estimator;

components CtpMultiplexC;
SubAMSend = CtpMultiplexC.SubAMSend;
SubAMPacket = CtpMultiplexC.SubAMPacket;
SubPacket = CtpMultiplexC.SubPacket;
SubReceive = CtpMultiplexC.SubReceive;
SubSnoop = CtpMultiplexC.SubSnoop;

components new AMQueueCtrlP(2);
AMQueueCtrlP.AMSend -> CtpMultiplexC.SubQueueAMSend;
SubAMPacket = AMQueueCtrlP.AMPacket;
SubPacket = AMQueueCtrlP.Packet;

CtpMultiplexC.QueueSend -> AMQueueCtrlP;
StdControl = AMQueueCtrlP;

}
