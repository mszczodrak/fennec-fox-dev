/*
 *  macx MAC module for Fennec Fox platform.
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
 * Module: macx MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 9/29/2012
 */

#include "macxMac.h"
#include "CC2420.h"

configuration macxMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface macxMacParams;

uses interface SplitControl as RadioControl;
uses interface RadioSend;
uses interface RadioReceive;
uses interface RadioCCA;
uses interface RadioPacket;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface LinkPacketMetadata;

}

implementation {

        #define UQ_METADATA_FLAGS       "UQ_CC2420X_METADATA_FLAGS"
        #define UQ_RADIO_ALARM          "UQ_CC2420X_RADIO_ALARM"


components macxMacP;
macxMacParams = macxMacP;

/*
components CC2420XActiveMessageC;
SplitControl = CC2420XActiveMessageC;
MacAMSend = CC2420XActiveMessageC.AMSend[100];
MacReceive = CC2420XActiveMessageC.Receive[100];
MacSnoop = CC2420XActiveMessageC.Snoop[100];
MacPacket = CC2420XActiveMessageC.Packet;
MacAMPacket = CC2420XActiveMessageC.AMPacket;
MacPacketAcknowledgements = CC2420XActiveMessageC.PacketAcknowledgements;
*/

components new ActiveMessageLayerC();
//ActiveMessageLayerC.Config -> RadioP;
ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
ActiveMessageLayerC.SubReceive -> TinyosNetworkLayerC.TinyosReceive;
ActiveMessageLayerC.SubPacket -> TinyosNetworkLayerC.TinyosPacket;

MacAMSend = ActiveMessageLayerC.AMSend[100];
MacReceive = ActiveMessageLayerC.Receive[100];
MacSnoop = ActiveMessageLayerC.Snoop[100];
//MacSendNotifier = ActiveMessageLayerC;
MacAMPacket = ActiveMessageLayerC;
MacPacket = ActiveMessageLayerC;


        components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;

// -------- Automatic RadioSend Resource

        components new AutoResourceAcquireLayerC();
        AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];
        AutoResourceAcquireLayerC -> TinyosNetworkLayerC.TinyosSend;


// -------- Ieee154 Message

        components new Ieee154MessageLayerC();
        Ieee154MessageLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;
        Ieee154MessageLayerC.SubSend -> TinyosNetworkLayerC.Ieee154Send;
        Ieee154MessageLayerC.SubReceive -> TinyosNetworkLayerC.Ieee154Receive;
        Ieee154MessageLayerC.RadioPacket -> TinyosNetworkLayerC.Ieee154Packet;

        //Ieee154Send = Ieee154MessageLayerC;
        //Ieee154Receive = Ieee154MessageLayerC;
        //Ieee154Notifier = Ieee154MessageLayerC;
        //Ieee154Packet = Ieee154PacketLayerC;
        //PacketForIeee154Message = Ieee154MessageLayerC;

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
        UniqueLayerC.Config -> RadioP;
        UniqueLayerC.SubSend -> PacketLinkLayerC;

// -------- Packet Link

        components new PacketLinkLayerC();
        //PacketLink = PacketLinkLayerC;
        PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
        PacketLinkLayerC -> LowPowerListeningLayerC.Send;
        PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
        PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;

// -------- Low Power Listening
#ifdef LOW_POWER_LISTENING
        #warning "*** USING LOW POWER LISTENING LAYER"
        components new LowPowerListeningLayerC();
        LowPowerListeningLayerC.Config -> RadioP;
        LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#else
        components new LowPowerListeningDummyC() as LowPowerListeningLayerC;
#endif
        LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
        LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
        LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
        LowPowerListeningLayerC.SubPacket -> TimeStampingLayerC;
        SplitControl = LowPowerListeningLayerC;
        //LowPowerListening = LowPowerListeningLayerC;

// -------- MessageBuffer

        components new MessageBufferLayerC();
        MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
        MessageBufferLayerC.RadioReceive -> UniqueLayerC;
        MessageBufferLayerC.RadioState = RadioState;
        //RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

        UniqueLayerC.SubReceive -> CollisionAvoidanceLayerC;

// -------- CollisionAvoidance


#ifdef SLOTTED_MAC
        components new SlottedCollisionLayerC() as CollisionAvoidanceLayerC;
#else
        components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
#endif
        CollisionAvoidanceLayerC.Config -> RadioP;
        CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
        CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
        CollisionAvoidanceLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

// -------- SoftwareAcknowledgement

        components new SoftwareAckLayerC();
        SoftwareAckLayerC.AckReceivedFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
        SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
        PacketAcknowledgements = SoftwareAckLayerC;
        SoftwareAckLayerC.Config -> RadioP;
        SoftwareAckLayerC.SubSend -> CsmaLayerC;
        SoftwareAckLayerC.SubReceive -> CsmaLayerC;

// -------- Carrier Sense

        components new DummyLayerC() as CsmaLayerC;
        CsmaLayerC.Config -> RadioP;
        CsmaLayerC = RadioSend;
        CsmaLayerC = RadioReceive;
        CsmaLayerC = RadioCCA;
// -------- TimeStamping

        components new TimeStampingLayerC();
        TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;
        TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
        PacketTimeStampRadio = TimeStampingLayerC;
        PacketTimeStampMilli = TimeStampingLayerC;
        TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];

// -------- MetadataFlags

        components new MetadataFlagsLayerC();
        MetadataFlagsLayerC.SubPacket = RadioPacket;

// -------- Driver







RadioControl = macxMacP.RadioControl;
//RadioSend = macxMacP.RadioSend;
//RadioReceive = macxMacP.RadioReceive;
//RadioCCA = macxMacP.RadioCCA;
//RadioPacket = macxMacP.RadioPacket;
PacketTransmitPower = macxMacP.PacketTransmitPower;
PacketRSSI = macxMacP.PacketRSSI;
PacketTimeSyncOffset = macxMacP.PacketTimeSyncOffset;
PacketLinkQuality = macxMacP.PacketLinkQuality;
LinkPacketMetadata = macxMacP.LinkPacketMetadata;





}

