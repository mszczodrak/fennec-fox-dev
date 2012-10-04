/*
 *  ControlUnit MAC module for Fennec Fox platform.
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
 * Module: ControlUnit MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 9/29/2012
 */

#include "ControlUnitMac.h"

configuration ControlUnitMacC {
  provides interface Mgmt;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface ControlUnitMacParams;
  uses interface Receive as RadioReceive;
  uses interface ModuleStatus as RadioStatus;

  uses interface RadioConfig;
  uses interface RadioPower;
  uses interface Read<uint16_t> as ReadRssi;
  uses interface Resource as RadioResource;

  uses interface SplitControl as RadioControl;
  uses interface RadioTransmit;
  uses interface ReceiveIndicator as PacketIndicator;
  uses interface ReceiveIndicator as ByteIndicator;
  uses interface ReceiveIndicator as EnergyIndicator;
}

implementation {

  components nullMacC as ControlUnitMacP;
  components ControlUnitParamsP;

  Mgmt = ControlUnitMacP;
  MacStatus = ControlUnitMacP;
  MacAMSend = ControlUnitMacP.MacAMSend;
  MacReceive = ControlUnitMacP.MacReceive;
  MacSnoop = ControlUnitMacP.MacSnoop;
  MacPacket = ControlUnitMacP.MacPacket;
  MacAMPacket = ControlUnitMacP.MacAMPacket;
  MacPacketAcknowledgements = ControlUnitMacP.MacPacketAcknowledgements;

  RadioConfig = ControlUnitMacP.RadioConfig;
  RadioPower = ControlUnitMacP.RadioPower;
  ReadRssi = ControlUnitMacP.ReadRssi;
  RadioResource = ControlUnitMacP.RadioResource;
  RadioStatus = ControlUnitMacP.RadioStatus;
  RadioTransmit = ControlUnitMacP.RadioTransmit;
  RadioControl = ControlUnitMacP.RadioControl;
  RadioReceive = ControlUnitMacP.RadioReceive;

  EnergyIndicator = ControlUnitMacP.EnergyIndicator;
  ByteIndicator = ControlUnitMacP.ByteIndicator;
  PacketIndicator = ControlUnitMacP.PacketIndicator;

  ControlUnitMacParams = ControlUnitParamsP.ControlUnitMacParams;
  ControlUnitMacP.nullMacParams -> ControlUnitParamsP.nullMacParams;

}

