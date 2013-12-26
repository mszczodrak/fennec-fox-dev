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

components macxMacP;
macxMacParams = macxMacP;


components CC2420XActiveMessageC;
SplitControl = CC2420XActiveMessageC;
MacAMSend = CC2420XActiveMessageC.AMSend[100];
MacReceive = CC2420XActiveMessageC.Receive[100];
MacSnoop = CC2420XActiveMessageC.Snoop[100];
MacPacket = CC2420XActiveMessageC.Packet;
MacAMPacket = CC2420XActiveMessageC.AMPacket;
MacPacketAcknowledgements = CC2420XActiveMessageC.PacketAcknowledgements;


RadioControl = macxMacP.RadioControl;
RadioSend = macxMacP.RadioSend;
RadioReceive = macxMacP.RadioReceive;
RadioCCA = macxMacP.RadioCCA;
RadioPacket = macxMacP.RadioPacket;
PacketTransmitPower = macxMacP.PacketTransmitPower;
PacketRSSI = macxMacP.PacketRSSI;
PacketTimeSyncOffset = macxMacP.PacketTimeSyncOffset;
PacketLinkQuality = macxMacP.PacketLinkQuality;
LinkPacketMetadata = macxMacP.LinkPacketMetadata;





}

