/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox TDMA MAC protocol
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/12/2012
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
  uses interface RadioBuffer;
  uses interface RadioSend;
  uses interface RadioPacket;
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

  RadioPacket = TDMAUniqueReceiveC.RadioPacket;

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

  RadioBuffer = TDMATransmitC.RadioBuffer;
  RadioSend = TDMATransmitC.RadioSend;
  RadioPacket = TDMATransmitC.RadioPacket;
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

