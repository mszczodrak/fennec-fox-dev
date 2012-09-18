/*
 *  TDMA MAC module for Fennec Fox platform.
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
 * Module: TDMA MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 8/29/2012
 */

#include "tdmaMac.h"

//#define LOW_POWER_LISTENING

configuration tdmaMacC {
  provides interface Mgmt;
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
  MacStatus = tdmaMacP;
  MacAMSend = tdmaMacP.MacAMSend;
  MacReceive = tdmaMacP.MacReceive;
  MacSnoop = tdmaMacP.MacSnoop;
  MacPacket = tdmaMacP.MacPacket;
  MacAMPacket = tdmaMacP.MacAMPacket;
  MacPacketAcknowledgements = tdmaMacP.MacPacketAcknowledgements;
  tdmaMacParams = tdmaMacP;

  RadioConfig = tdmaMacP.RadioConfig;
  RadioPower = tdmaMacP.RadioPower;
  ReadRssi = tdmaMacP.ReadRssi;
  RadioResource = tdmaMacP.RadioResource;

  RadioStatus = tdmaMacP.RadioStatus;

  components CsmaC;
  RadioPower = CsmaC.RadioPower;
  RadioResource = CsmaC.RadioResource;

  components DefaultLplC as LplC;
  tdmaMacP.RadioControl -> LplC.SplitControl;

  components UniqueSendC;
  components UniqueReceiveC;

  tdmaMacP.SubSend -> UniqueSendC;
  tdmaMacP.SubReceive -> LplC;

  // SplitControl Layers

  LplC.MacPacketAcknowledgements -> tdmaMacP.MacPacketAcknowledgements;
  LplC.SubControl -> CsmaC;

  UniqueSendC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;

  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive =  RadioReceive;

  components PowerCycleC;
  PacketIndicator = PowerCycleC.PacketIndicator;
  EnergyIndicator = PowerCycleC.EnergyIndicator;
  ByteIndicator = PowerCycleC.ByteIndicator;

  tdmaMacParams = PowerCycleC.tdmaMacParams;
  tdmaMacParams = LplC.tdmaMacParams;
  tdmaMacParams = CsmaC.tdmaMacParams;

  components RandomC;
  tdmaMacP.Random -> RandomC;

  components macTransmitC;
  tdmaMacParams = macTransmitC.tdmaMacParams;
  RadioTransmit = macTransmitC.RadioTransmit;
  EnergyIndicator = macTransmitC.EnergyIndicator;

  CsmaC.MacTransmit -> macTransmitC.MacTransmit;
  LplC.MacTransmit -> macTransmitC.MacTransmit;

  CsmaC.SubControl -> macTransmitC.StdControl;
 
  RadioControl = macTransmitC.RadioControl;


  /* FTSP */
  components FtspActiveMessageC;

  FtspActiveMessageC.MacAMSend -> tdmaMacP.FtspMacAMSend;
  FtspActiveMessageC.MacReceive -> tdmaMacP.FtspMacReceive;
  FtspActiveMessageC.MacAMPacket -> tdmaMacP.MacAMPacket;
  FtspActiveMessageC.MacPacket -> tdmaMacP.MacPacket;
  FtspActiveMessageC.MacPacketAcknowledgements -> tdmaMacP.MacPacketAcknowledgements;
  FtspActiveMessageC.MacStatus -> tdmaMacP.MacStatus;

  components MainC;
#ifdef SYNC_PREC_TMILLI
  components TimeSyncC as TimeSyncC;
#endif

#ifdef SYNC_PREC_32K
  components TimeSyncC as TimeSync32kC;
#endif

  MainC.SoftwareInit -> TimeSyncC;
  TimeSyncC.Boot -> MainC;

  components FennecPacketC;
  tdmaMacP.PacketTimeStamp -> FennecPacketC;
  tdmaMacP.GlobalTime -> TimeSyncC;
  tdmaMacP.TimeSyncInfo -> TimeSyncC;

  /* additional timer */
  components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
  LocalTime32khzC.Counter -> Counter32khz32C;

#ifdef SYNC_PREC_32K
  tdmaMacP.LocalTime -> LocalTime32khzC;
#endif

#ifdef SYNC_PREC_TMILLI
  tdmaMacP.LocalTime -> LocalTimeMilliC;
#endif

}

