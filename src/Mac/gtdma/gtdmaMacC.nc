/*
 *  gtdma mac module for Fennec Fox platform.
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
 * Module: gtdma Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration gtdmaMacC {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface gtdmaMacParams;

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
  components gtdmaMacP;
  Mgmt = gtdmaMacP;
  Module = gtdmaMacP;
  gtdmaMacParams = gtdmaMacP;
  MacAMSend = gtdmaMacP.MacAMSend;
  MacReceive = gtdmaMacP.MacReceive;
  MacSnoop = gtdmaMacP.MacSnoop;
  MacAMPacket = gtdmaMacP.MacAMPacket;
  MacPacket = gtdmaMacP.MacPacket;
  MacPacketAcknowledgements = gtdmaMacP.MacPacketAcknowledgements;
  MacStatus = gtdmaMacP.MacStatus;
  RadioReceive = gtdmaMacP.RadioReceive;
  RadioStatus = gtdmaMacP.RadioStatus;

  RadioConfig = gtdmaMacP.RadioConfig;
  RadioPower = gtdmaMacP.RadioPower;
  ReadRssi = gtdmaMacP.ReadRssi;
  RadioResource = gtdmaMacP.RadioResource;
  PacketIndicator = gtdmaMacP.PacketIndicator;
  EnergyIndicator = gtdmaMacP.EnergyIndicator;
  ByteIndicator = gtdmaMacP.ByteIndicator;
  RadioTransmit = gtdmaMacP.RadioTransmit;
  RadioControl = gtdmaMacP.RadioControl;
}

