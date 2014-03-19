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
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;

uses interface RadioReceive;

uses interface Resource as RadioResource;
uses interface SplitControl as RadioControl;
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


#ifdef LOW_POWER_LISTENING
                interface LowPowerListeningConfig;
#endif

uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface SoftwareAckConfig;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;

uses interface RadioAlarm[uint8_t id];
}

implementation
{
	#define UQ_RADIO_ALARM		"UQ_CC2420X_RADIO_ALARM"

/*
	csmaConfigP.Ieee154PacketLayer -> Ieee154PacketLayerC;
///// 	csmaConfigP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	csmaConfigP.RadioAlarm -> RadioAlarmC.RadioAlarm[process];
	csmaConfigP.PacketTimeStamp -> TimeStampingLayerC;
	RadioPacket = csmaConfigP.CC2420XPacket;
*/

// -------- RadioAlarm

/////	components new RadioAlarmC();
/////	RadioAlarmC.Alarm -> RadioDriverLayerC;

// -------- Active Message

#ifndef IEEE154FRAMES_ENABLED
	components new ActiveMessageLayerC();
	RadioActiveMessageConfig = ActiveMessageLayerC.Config;
	ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
	ActiveMessageLayerC.SubReceive -> TinyosNetworkLayerC.TinyosReceive;
	ActiveMessageLayerC.SubPacket -> TinyosNetworkLayerC.TinyosPacket;

	MacAMSend = ActiveMessageLayerC.AMSend[process];
	MacReceive = ActiveMessageLayerC.Receive[process];
	MacSnoop = ActiveMessageLayerC.Snoop[process];
/////	//SendNotifier = ActiveMessageLayerC;
	MacAMPacket = ActiveMessageLayerC.AMPacket;
/////	PacketForActiveMessage = ActiveMessageLayerC;

/////	//ReceiveDefault = ActiveMessageLayerC.ReceiveDefault;
////	//SnoopDefault = ActiveMessageLayerC.SnoopDefault;
#endif

// -------- Automatic RadioSend Resource

#ifndef IEEE154FRAMES_ENABLED
#ifndef TFRAMES_ENABLED
components new AutoResourceAcquireLayerC();
RadioResource = AutoResourceAcquireLayerC.Resource;

#else
components new DummyLayerC() as AutoResourceAcquireLayerC;
#endif
AutoResourceAcquireLayerC -> TinyosNetworkLayerC.TinyosSend;
#endif

// -------- RadioSend Resource


// -------- Tinyos Network

	components new TinyosNetworkLayerC();

	TinyosNetworkLayerC.SubSend -> UniqueLayerC;
	TinyosNetworkLayerC.SubReceive -> PacketLinkLayerC;
	TinyosNetworkLayerC.SubPacket -> Ieee154PacketLayerC;

// -------- IEEE 802.15.4 Packet

	components new Ieee154PacketLayerC();
	Ieee154PacketLayerC.SubPacket -> PacketLinkLayerC;

// -------- UniqueLayer Send part (wired twice)

	components new UniqueLayerC();
	RadioUniqueConfig = UniqueLayerC.Config;
	UniqueLayerC.SubSend -> PacketLinkLayerC;

// -------- Packet Link

	components new PacketLinkLayerC();
/////	PacketLink = PacketLinkLayerC;
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
	PacketLinkLayerC -> LowPowerListeningLayerC.Send;
	PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
	PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;
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
	RadioSlottedCollisionConfig = CollisionAvoidanceLayerC.Config;
#else
	components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
	RadioRandomCollisionConfig = CollisionAvoidanceLayerC.Config;
#endif
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
	////CollisionAvoidanceLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	RadioAlarm[unique(UQ_RADIO_ALARM)] = CollisionAvoidanceLayerC.RadioAlarm;

// -------- SoftwareAcknowledgement

	components new SoftwareAckLayerC();
	AckReceivedFlag = SoftwareAckLayerC.AckReceivedFlag;
	///SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	RadioAlarm[unique(UQ_RADIO_ALARM)] = SoftwareAckLayerC.RadioAlarm;
	MacPacketAcknowledgements = SoftwareAckLayerC.PacketAcknowledgements;
	RadioSoftwareAckConfig = SoftwareAckLayerC.Config;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> CsmaLayerC;

// -------- Carrier Sense

	components new DummyLayerC() as CsmaLayerC;
	//RadioCsmaConfig = CsmaLayerC.Config;
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
	RadioTrafficMonitorConfig = TrafficMonitorLayerC.Config;
#else
	components new DummyLayerC() as TrafficMonitorLayerC;
#endif
	RadioSend = TrafficMonitorLayerC.SubSend;
	RadioReceive = TrafficMonitorLayerC.SubReceive;
	RadioState = TrafficMonitorLayerC.SubState;

}
