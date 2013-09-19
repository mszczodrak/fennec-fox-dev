/*
 *  cu MAC module for Fennec Fox platform.
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
 * Module: cu MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 8/29/2012
 */

#include "cuMac.h"

configuration cuMacC {
provides interface Mgmt;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface cuMacParams;

uses interface Receive as RadioReceive;

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
}

implementation {

components cuMacP;

Mgmt = cuMacP;
MacAMSend = cuMacP.MacAMSend;
MacReceive = cuMacP.MacReceive;
MacSnoop = cuMacP.MacSnoop;
MacPacket = cuMacP.MacPacket;
MacAMPacket = cuMacP.MacAMPacket;
MacPacketAcknowledgements = cuMacP.MacPacketAcknowledgements;
cuMacParams = cuMacP;

RadioConfig = cuMacP.RadioConfig;
RadioPower = cuMacP.RadioPower;
ReadRssi = cuMacP.ReadRssi;
RadioResource = cuMacP.RadioResource;
RadioPacket = cuMacP.RadioPacket;

components cuTransmitC;
RadioPower = cuTransmitC.RadioPower;
RadioResource = cuTransmitC.RadioResource;

cuMacP.RadioControl -> cuTransmitC;

cuMacP.SubSend -> cuTransmitC;
RadioReceive = cuMacP.SubReceive;

PacketIndicator = cuMacP.PacketIndicator;
ByteIndicator = cuMacP.ByteIndicator;

cuMacParams = cuTransmitC.cuMacParams;

components RandomC;
cuMacP.Random -> RandomC;

RadioBuffer = cuTransmitC.RadioBuffer;
RadioSend = cuTransmitC.RadioSend;
RadioPacket = cuTransmitC.RadioPacket;
EnergyIndicator = cuTransmitC.EnergyIndicator;
RadioControl = cuTransmitC.RadioControl;
}

