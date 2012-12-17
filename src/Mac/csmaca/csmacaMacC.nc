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
  provides interface Mgmt;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface csmacaMacParams;

  uses interface Receive as RadioReceive;
  uses interface ModuleStatus as RadioStatus;

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

  components csmacaMacP;

  Mgmt = csmacaMacP;
  MacStatus = csmacaMacP;
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

  RadioStatus = csmacaMacP.RadioStatus;

  components CSMATransmitC;
  RadioPower = CSMATransmitC.RadioPower;
  RadioResource = CSMATransmitC.RadioResource;

  components DefaultLplC as LplC;
  csmacaMacP.RadioControl -> LplC.SplitControl;

  components UniqueSendC;
  components UniqueReceiveC;

  csmacaMacP.SubSend -> UniqueSendC;
  csmacaMacP.SubReceive -> LplC;

  // SplitControl Layers

  LplC.MacPacketAcknowledgements -> csmacaMacP.MacPacketAcknowledgements;
  LplC.SubControl -> CSMATransmitC;

  UniqueSendC.SubSend -> LplC.Send;
  LplC.SubSend -> CSMATransmitC;

  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive =  RadioReceive;

  components PowerCycleC;
  PacketIndicator = PowerCycleC.PacketIndicator;
  EnergyIndicator = PowerCycleC.EnergyIndicator;
  ByteIndicator = PowerCycleC.ByteIndicator;

  csmacaMacParams = PowerCycleC.csmacaMacParams;
  csmacaMacParams = LplC.csmacaMacParams;
  csmacaMacParams = CSMATransmitC.csmacaMacParams;

  components RandomC;
  csmacaMacP.Random -> RandomC;

  RadioBuffer = CSMATransmitC.RadioBuffer;
  RadioSend = CSMATransmitC.RadioSend;
  RadioPacket = CSMATransmitC.RadioPacket;
  EnergyIndicator = CSMATransmitC.EnergyIndicator;
  LplC.CSMATransmit -> CSMATransmitC.CSMATransmit;
  RadioControl = CSMATransmitC.RadioControl;
}

