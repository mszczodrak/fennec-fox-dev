/*
 *  tdma mac module for Fennec Fox platform.
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
 * Module: tdma Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration tdmaMacC {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface tdmaMacParams;

  uses interface Receive as RadioReceive;
  uses interface ModuleStatus as RadioStatus;

  uses interface RadioConfig;
  uses interface RadioPower;
  uses interface Read<uint16_t> as ReadRssi;
  uses interface Resource as RadioResource;

  uses interface StdControl as RadioControl;
  uses interface RadioTransmit;
  uses interface ReceiveIndicator as PacketIndicator;
  uses interface ReceiveIndicator as ByteIndicator;
  uses interface ReceiveIndicator as EnergyIndicator;
}

implementation {
  components tdmaMacP;
  Mgmt = tdmaMacP;
  Module = tdmaMacP;
  tdmaMacParams = tdmaMacP;
  MacAMSend = tdmaMacP.MacAMSend;
  MacReceive = tdmaMacP.MacReceive;
  MacSnoop = tdmaMacP.MacSnoop;
  MacAMPacket = tdmaMacP.MacAMPacket;
  MacPacket = tdmaMacP.MacPacket;
  MacPacketAcknowledgements = tdmaMacP.MacPacketAcknowledgements;
  MacStatus = tdmaMacP.MacStatus;
  RadioReceive = tdmaMacP.RadioReceive;
  RadioStatus = tdmaMacP.RadioStatus;

  RadioConfig = tdmaMacP.RadioConfig;
  RadioPower = tdmaMacP.RadioPower;
  ReadRssi = tdmaMacP.ReadRssi;
  RadioResource = tdmaMacP.RadioResource;
  PacketIndicator = tdmaMacP.PacketIndicator;
  EnergyIndicator = tdmaMacP.EnergyIndicator;
  ByteIndicator = tdmaMacP.ByteIndicator;
  RadioTransmit = tdmaMacP.RadioTransmit;
  RadioControl = tdmaMacP.RadioControl;

  components FtspC;
}

