/*
 * Copyright (c) 2014, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
  * Fennec Fox cc2420x adaptation
  *
  * @author: Marcin K Szczodrak
  */

#include <RadioConfig.h>

configuration cc2420xC {

provides interface SplitControl;
provides interface AMSend[process_t process_id];
provides interface Receive[process_t process_id];
provides interface Receive as Snoop[process_t process_id];
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;
provides interface LinkPacketMetadata;

uses interface Param;
uses interface StdControl as AMQueueControl;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;

}

implementation
{

components cc2420xP;
components CC2420XActiveMessageC as AM;
components CC2420XRadioP as RadioP;

Param = cc2420xP;
Param = RadioP.Param;
SplitControl = cc2420xP.SplitControl;
AMQueueControl = cc2420xP.AMQueueControl;
AMSend = cc2420xP.AMSend;
Receive = cc2420xP.Receive;
Snoop = cc2420xP.Snoop;

cc2420xP.RadioParamsControl -> RadioP.StdControl;

cc2420xP.SubSplitControl -> AM.SplitControl;
cc2420xP.PacketTransmitPower -> AM.PacketTransmitPower;
cc2420xP.RadioChannel -> AM.RadioChannel;
cc2420xP.SubAMSend -> AM.AMSend;
cc2420xP.SubReceive -> AM.Receive;
cc2420xP.SubSnoop -> AM.Snoop;
cc2420xP.AMPacket -> AM.AMPacket;
cc2420xP.Packet -> AM.Packet;
cc2420xP.LowPowerListening -> AM.LowPowerListening;
cc2420xP.PacketAcknowledgements -> AM.PacketAcknowledgements;

Packet = AM.Packet;
AMPacket = AM.AMPacket;
LowPowerListening = AM.LowPowerListening;
RadioChannel = AM.RadioChannel;
PacketTimeStampRadio = AM.PacketTimeStampRadio;
PacketTimeStampMilli = AM.PacketTimeStampMilli;
PacketTimeStamp32khz = AM.PacketTimeStamp32khz;
PacketAcknowledgements = AM.PacketAcknowledgements;
LinkPacketMetadata = AM.LinkPacketMetadata;
PacketLinkQuality = AM.PacketLinkQuality;
PacketTransmitPower = AM.PacketTransmitPower;
PacketRSSI = AM.PacketRSSI;

#ifdef __DBGS__
components CC2420XDriverLayerP;
components SerialDbgsC;
CC2420XDriverLayerP.SerialDbgs -> SerialDbgsC.SerialDbgs[242];
#endif


}
