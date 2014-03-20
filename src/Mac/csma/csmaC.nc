/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai, Miklos Maroti
 */

#include <RadioConfig.h>

generic configuration csmaC(process_t process) {

provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmaParams;

/* new */
provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;


/* to Radio */
provides interface Ieee154PacketLayer;

uses interface RadioReceive;

uses interface Resource as RadioResource;
uses interface RadioPacket;
uses interface RadioSend;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface PacketFlag as AckReceivedFlag;


uses interface RadioCCA;
uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;


uses interface ActiveMessageConfig;
uses interface UniqueConfig;
uses interface LowPowerListeningConfig;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface SoftwareAckConfig;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;

uses interface RadioAlarm[uint8_t id];

uses interface PacketTimeStamp<TRadio, uint32_t> as RadioPacketTimeStampRadio;
uses interface PacketTimeStamp<TMilli, uint32_t> as RadioPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as RadioPacketTimeStamp32khz;

}

implementation
{

components new csmaP(process);
csmaParams = csmaP.csmaParams;
PacketTransmitPower = csmaP.PacketTransmitPower;
PacketRSSI = csmaP.PacketRSSI;
PacketLinkQuality = csmaP.PacketLinkQuality;
TrafficMonitorConfig = csmaP.TrafficMonitorConfig;
LowPowerListeningConfig = csmaP.LowPowerListeningConfig;
CsmaConfig = csmaP.CsmaConfig;
SlottedCollisionConfig = csmaP.SlottedCollisionConfig;

Ieee154PacketLayer = Ieee154PacketLayerC;
MacLinkPacketMetadata = RadioLinkPacketMetadata;
MacPacketTimeStampRadio = RadioPacketTimeStampRadio;
MacPacketTimeStampMilli = RadioPacketTimeStampMilli;
MacPacketTimeStamp32khz = RadioPacketTimeStamp32khz;

#define UQ_RADIO_ALARM		"UQ_CC2420X_RADIO_ALARM"

// -------- Active Message

components new ActiveMessageLayerC();
components new AutoResourceAcquireLayerC();
components new Ieee154PacketLayerC();
components new UniqueLayerC();
components new PacketLinkLayerC();

MacAMSend = ActiveMessageLayerC.AMSend[process];
MacReceive = ActiveMessageLayerC.Receive[process];
MacSnoop = ActiveMessageLayerC.Snoop[process];
/////	//SendNotifier = ActiveMessageLayerC;
MacAMPacket = ActiveMessageLayerC.AMPacket;
MacPacket = ActiveMessageLayerC;


ActiveMessageConfig = ActiveMessageLayerC.Config;
ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
ActiveMessageLayerC.SubReceive -> PacketLinkLayerC;
ActiveMessageLayerC.SubPacket -> Ieee154PacketLayerC;

RadioResource = AutoResourceAcquireLayerC.Resource;
AutoResourceAcquireLayerC.SubSend -> UniqueLayerC;

Ieee154PacketLayerC.SubPacket -> PacketLinkLayerC;

UniqueConfig = UniqueLayerC.Config;
UniqueLayerC.SubSend -> PacketLinkLayerC;

PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
PacketLinkLayerC -> LowPowerListeningLayerC.Send;
PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;

// -------- Low Power Listening

#ifdef LOW_POWER_LISTENING
#warning "*** USING LOW POWER LISTENING LAYER"
components new LowPowerListeningLayerC();
RadioLowPowerListeningConfig = LowPowerListeningLayerC.Config;
LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#else	
components new LowPowerListeningDummyC() as LowPowerListeningLayerC;
#endif
LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
//LowPowerListeningLayerC.SubPacket -> TimeStampingLayerC;
RadioPacket = LowPowerListeningLayerC.SubPacket;
SplitControl = LowPowerListeningLayerC;
LowPowerListening = LowPowerListeningLayerC;

// -------- MessageBuffer

components new MessageBufferLayerC();
MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
MessageBufferLayerC.RadioReceive -> UniqueLayerC;
MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;
RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

UniqueLayerC.SubReceive -> CollisionAvoidanceLayerC;

// -------- CollisionAvoidance

#ifdef SLOTTED_MAC
components new SlottedCollisionLayerC() as CollisionAvoidanceLayerC;
SlottedCollisionConfig = CollisionAvoidanceLayerC.Config;
#else
components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
RandomCollisionConfig = CollisionAvoidanceLayerC.Config;
#endif
CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
RadioAlarm[unique(UQ_RADIO_ALARM)] = CollisionAvoidanceLayerC;

// -------- SoftwareAcknowledgement

components new SoftwareAckLayerC();
AckReceivedFlag = SoftwareAckLayerC.AckReceivedFlag;
RadioAlarm[unique(UQ_RADIO_ALARM)] = SoftwareAckLayerC.RadioAlarm;
MacPacketAcknowledgements = SoftwareAckLayerC.PacketAcknowledgements;
SoftwareAckConfig = SoftwareAckLayerC.Config;
SoftwareAckLayerC.SubSend -> CsmaLayerC;
SoftwareAckLayerC.SubReceive -> CsmaLayerC;

// -------- Carrier Sense

components new DummyLayerC() as CsmaLayerC;
//CsmaConfig = CsmaLayerC.Config;
CsmaLayerC -> TrafficMonitorLayerC.RadioSend;
CsmaLayerC -> TrafficMonitorLayerC.RadioReceive;
RadioCCA = CsmaLayerC;

// -------- MetadataFlags

/////	components new MetadataFlagsLayerC();
/////	RadioPacket = MetadataFlagsLayerC.SubPacket;

// -------- Traffic Monitor

#ifdef TRAFFIC_MONITOR
components new TrafficMonitorLayerC();
TrafficMonitor = TrafficMonitorLayerC;
TrafficMonitorConfig = TrafficMonitorLayerC.Config;
#else
components new DummyLayerC() as TrafficMonitorLayerC;
#endif
RadioSend = TrafficMonitorLayerC.SubSend;
RadioReceive = TrafficMonitorLayerC.SubReceive;
RadioState = TrafficMonitorLayerC.SubState;

}
