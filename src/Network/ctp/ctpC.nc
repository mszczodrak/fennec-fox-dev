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
  * Fennec Fox CTP Network Protocol adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/18/2010
  */



#include <Fennec.h>
#include <Ctp.h>

generic configuration ctpC(process_t process) {
provides interface SplitControl;

uses interface ctpParams;

provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;
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


components new ctpP(process);
components LedsC;
components new CtpActiveMessageC();
components new CtpForwardingEngineP(process) as Forwarder;


SplitControl = ctpP;
ctpParams = ctpP;
NetworkAMSend = ctpP;
NetworkAMPacket = ctpP;
NetworkPacket = ctpP;
NetworkPacketAcknowledgements = ctpP;

ctpP.Leds -> LedsC;


NetworkReceive = Forwarder.Receive;
NetworkSnoop = Forwarder.Snoop;

MacAMSend = CtpActiveMessageC;
MacReceive = CtpActiveMessageC.MacReceive;
MacSnoop = CtpActiveMessageC.MacSnoop;
MacAMPacket = CtpActiveMessageC.MacAMPacket;
MacPacket = CtpActiveMessageC.MacPacket;
MacPacketAcknowledgements = CtpActiveMessageC.MacPacketAcknowledgements;
LowPowerListening = ctpP;
RadioChannel = ctpP;

ctpP.RoutingControl -> Forwarder.StdControl;


Forwarder.Leds -> LedsC;

components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
Forwarder.QEntryPool -> QEntryPoolP;
Forwarder.MessagePool -> MessagePoolP;

components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
Forwarder.SendQueue -> SendQueueP;

components new LruCtpMsgCacheP(CACHE_SIZE) as SentCacheP;
ctpP.RoutingControl -> SentCacheP;
Forwarder.SentCache -> SentCacheP;

components MainC;
MainC.SoftwareInit -> SentCacheP;
SentCacheP.CtpPacket -> Forwarder;

components new TimerMilliC() as RoutingBeaconTimer;
components new TimerMilliC() as RouteUpdateTimer;
components new LinkEstimatorP() as Estimator;
Forwarder.LinkEstimator -> Estimator;

components new CtpRoutingEngineP(process, TREE_ROUTING_TABLE_SIZE, 128, 512000) as Router;

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


ctpP.RoutingControl -> Router.StdControl;
ctpP.RoutingControl -> Estimator.StdControl;

ctpP.RootControl -> Router;

Router.BeaconSend -> Estimator.Send;
Router.BeaconReceive -> Estimator.Receive;
Router.LinkEstimator -> Estimator.LinkEstimator;

Router.CompareBit -> Estimator.CompareBit;
Router.AMPacket -> CtpActiveMessageC;
Router.BeaconTimer -> RoutingBeaconTimer;
Router.RouteTimer -> RouteUpdateTimer;
Forwarder.CtpInfo -> Router;
Router.CtpCongestion -> Forwarder;

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

Estimator.Random -> RandomC;

Estimator.AMSend -> SendControl;
Estimator.SubReceive -> CtpActiveMessageC.Receive[AM_CTP_ROUTING]; //ReceiveControl;

Estimator.SubPacket -> CtpActiveMessageC;
Estimator.SubAMPacket -> CtpActiveMessageC;

ctpP.CtpSend -> Forwarder.Send[unique(UQ_CTP_CLIENT)];
ctpP.CtpPacket -> Forwarder.Packet;
ctpP.CtpPacketAcknowledgements -> CtpActiveMessageC.PacketAcknowledgements;

ctpP.CtpAMPacket -> Forwarder.AMPacket;
MacLinkPacketMetadata = Estimator.MacLinkPacketMetadata;
}
