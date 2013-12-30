/*
 *  csma/ca MAC module for Fennec Fox platform.
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
 * Module: CSMA/CA MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 8/29/2012
 */

#include "csmacaMac.h"

configuration csmacaMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface csmacaMacParams;

uses interface RadioReceive;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface SplitControl as RadioControl;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;
uses interface ReceiveIndicator as PacketIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as EnergyIndicator;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioCCA;

uses interface RadioState;
uses interface LinkPacketMetadata;
}

implementation {

components csmacaMacP;

SplitControl = csmacaMacP;
MacAMSend = csmacaMacP.MacAMSend;
MacReceive = csmacaMacP.MacReceive;
MacSnoop = csmacaMacP.MacSnoop;
MacPacket = csmacaMacP.MacPacket;
MacAMPacket = csmacaMacP.MacAMPacket;
MacPacketAcknowledgements = csmacaMacP.MacPacketAcknowledgements;
csmacaMacParams = csmacaMacP;

RadioConfig = csmacaMacP.RadioConfig;
RadioPower = csmacaMacP.RadioPower;
ReadRssi = csmacaMacP.ReadRssi;
RadioResource = csmacaMacP.RadioResource;
RadioPacket = csmacaMacP.RadioPacket;


RadioState = csmacaMacP.RadioState;
LinkPacketMetadata = csmacaMacP.LinkPacketMetadata;

components CSMATransmitC;
RadioPower = CSMATransmitC.RadioPower;
RadioResource = CSMATransmitC.RadioResource;

components DefaultLplC as LplC;
csmacaMacP.RadioControl -> LplC.SplitControl;

components UniqueSendC;
components UniqueReceiveC;

RadioPacket = UniqueReceiveC.RadioPacket;

csmacaMacP.SubSend -> UniqueSendC;
csmacaMacP.SubReceive -> LplC;

// SplitControl Layers

LplC.MacPacketAcknowledgements -> csmacaMacP.MacPacketAcknowledgements;
LplC.SubControl -> CSMATransmitC;

UniqueSendC.SubSend -> LplC.Send;
LplC.SubSend -> CSMATransmitC;

LplC.SubReceive -> UniqueReceiveC.Receive;
UniqueReceiveC.SubReceive = RadioReceive;

PacketIndicator = LplC.PacketIndicator;
EnergyIndicator = LplC.EnergyIndicator;
ByteIndicator = LplC.ByteIndicator;
RadioCCA = LplC.RadioCCA;

PacketTransmitPower = LplC.PacketTransmitPower;
PacketRSSI = LplC.PacketRSSI;
PacketTimeSyncOffset = LplC.PacketTimeSyncOffset;
PacketLinkQuality = LplC.PacketLinkQuality;


csmacaMacParams = LplC.csmacaMacParams;
csmacaMacParams = CSMATransmitC.csmacaMacParams;

components RandomC;
csmacaMacP.Random -> RandomC;

components LedsC;
csmacaMacP.Leds -> LedsC;

RadioBuffer = CSMATransmitC.RadioBuffer;
RadioSend = CSMATransmitC.RadioSend;
RadioPacket = CSMATransmitC.RadioPacket;
EnergyIndicator = CSMATransmitC.EnergyIndicator;
RadioCCA = CSMATransmitC.RadioCCA;
PacketTransmitPower = CSMATransmitC.PacketTransmitPower;
PacketRSSI = CSMATransmitC.PacketRSSI;
PacketTimeSyncOffset = CSMATransmitC.PacketTimeSyncOffset;
PacketLinkQuality = CSMATransmitC.PacketLinkQuality;

LplC.CSMATransmit -> CSMATransmitC.CSMATransmit;
RadioControl = CSMATransmitC.RadioControl;
}

