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

  uses interface SplitControl as RadioControl;
  uses interface RadioTransmit;
  uses interface ReceiveIndicator as PacketIndicator;
  uses interface ReceiveIndicator as ByteIndicator;
  uses interface ReceiveIndicator as EnergyIndicator;
}

implementation {

#define TDMA_QUEUE_SIZE	20

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

  components TDMATransmitC;
  RadioPower = TDMATransmitC.RadioPower;
  RadioResource = TDMATransmitC.RadioResource;

  tdmaMacP.RadioControl -> TDMATransmitC;

  components TDMAUniqueSendC;
  components TDMAUniqueReceiveC;

  tdmaMacP.SubSend -> TDMAUniqueSendC;
  tdmaMacP.SubReceive -> TDMAUniqueReceiveC.Receive;

  components LedsC;
  tdmaMacP.Leds -> LedsC;

  // SplitControl Layers

  TDMAUniqueSendC.SubSend -> TDMATransmitC;
  TDMAUniqueReceiveC.SubReceive =  RadioReceive;

  EnergyIndicator = tdmaMacP.EnergyIndicator;
  ByteIndicator = tdmaMacP.ByteIndicator;
  PacketIndicator = tdmaMacP.PacketIndicator;

  tdmaMacParams = TDMATransmitC.tdmaMacParams;

  components RandomC;
  tdmaMacP.Random -> RandomC;

  RadioTransmit = TDMATransmitC.RadioTransmit;
  EnergyIndicator = TDMATransmitC.EnergyIndicator;
  RadioControl = TDMATransmitC.RadioControl;

  components new QueueC(message_t*, TDMA_QUEUE_SIZE) as SendQueueP;
  tdmaMacP.SendQueue -> SendQueueP;

  /* FTSP */
  components FtspActiveMessageC;

  FtspActiveMessageC.MacAMSend -> tdmaMacP.FtspMacAMSend;
  FtspActiveMessageC.MacReceive -> tdmaMacP.FtspMacReceive;
  FtspActiveMessageC.MacAMPacket -> tdmaMacP.MacAMPacket;
  FtspActiveMessageC.MacPacket -> tdmaMacP.MacPacket;
  FtspActiveMessageC.MacPacketAcknowledgements -> tdmaMacP.MacPacketAcknowledgements;
  FtspActiveMessageC.MacStatus -> tdmaMacP.MacStatus;

  components TimeSyncC as TimeSyncC;
//  components TimeSync32kC as TimeSyncC;

  components FennecPacketC;
  tdmaMacP.PacketTimeStamp -> FennecPacketC;
  tdmaMacP.GlobalTime -> TimeSyncC;
  tdmaMacP.TimeSyncInfo -> TimeSyncC;
  tdmaMacP.TimeSyncMode -> TimeSyncC;
  tdmaMacP.TimeSyncNotify -> TimeSyncC;

  components new TimerMilliC() as PeriodTimerC;
  tdmaMacP.PeriodTimer ->  PeriodTimerC;

  components new TimerMilliC() as FrameTimerC;
  tdmaMacP.FrameTimer ->  FrameTimerC;

  tdmaMacP.TimerControl -> TimeSyncC;
  tdmaMacParams = TimeSyncC;

}

