/*
 *  null MAC module for Fennec Fox platform.
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
 * Module: null MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 9/29/2012
 */

#include "nullMac.h"

configuration nullMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface nullMacParams;
uses interface Receive as RadioReceive;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface SplitControl as RadioControl;
uses interface RadioPacket;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface ReceiveIndicator as PacketIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as EnergyIndicator;
}

implementation {

components nullMacP;
SplitControl = nullMacP;
MacAMSend = nullMacP.MacAMSend;
MacReceive = nullMacP.MacReceive;
MacSnoop = nullMacP.MacSnoop;
MacPacket = nullMacP.MacPacket;
MacAMPacket = nullMacP.MacAMPacket;
MacPacketAcknowledgements = nullMacP.MacPacketAcknowledgements;

nullMacParams = nullMacP;

RadioConfig = nullMacP.RadioConfig;
RadioPower = nullMacP.RadioPower;
ReadRssi = nullMacP.ReadRssi;
RadioResource = nullMacP.RadioResource;
RadioPacket = nullMacP.RadioPacket;
RadioBuffer = nullMacP.RadioBuffer;
RadioSend = nullMacP.RadioSend;
RadioControl = nullMacP.RadioControl;
RadioReceive = nullMacP.RadioReceive;

EnergyIndicator = nullMacP.EnergyIndicator;
ByteIndicator = nullMacP.ByteIndicator;
PacketIndicator = nullMacP.PacketIndicator;

components RandomC;
nullMacP.Random -> RandomC;
components new StateC();
nullMacP.SplitControlState -> StateC;
}

