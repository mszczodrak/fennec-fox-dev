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
  * Fennec Fox rf231 adaptation
  *
  * @author: Marcin K Szczodrak
  */

#include <RadioConfig.h>

configuration rf231C {

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

uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;
}

implementation
{

components rf231P;
components RF231ActiveMessageC as AM;
components RF231RadioP as RadioP;

Param = rf231P;
SplitControl = rf231P.SplitControl;
AMQueueControl = rf231P.AMQueueControl;
AMSend = rf231P.AMSend;
Receive = rf231P.Receive;
Snoop = rf231P.Snoop;

rf231P.SubSplitControl -> AM.SplitControl;
rf231P.PacketTransmitPower -> AM.PacketTransmitPower;
rf231P.RadioChannel -> AM.RadioChannel;
rf231P.SubAMSend -> AM.AMSend;
rf231P.SubReceive -> AM.Receive;
rf231P.SubSnoop -> AM.Snoop;
rf231P.AMPacket -> AM.AMPacket;
rf231P.Packet -> AM.Packet;
rf231P.LowPowerListening -> AM.LowPowerListening;
rf231P.PacketAcknowledgements -> AM.PacketAcknowledgements;

Packet = AM.Packet;
AMPacket = AM.AMPacket;
LowPowerListening = AM.LowPowerListening;
RadioChannel = AM.RadioChannel;
PacketTimeStampRadio = AM.PacketTimeStampRadio;
PacketTimeStampMilli = AM.PacketTimeStampMilli;
PacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;
PacketAcknowledgements = AM.PacketAcknowledgements;
LinkPacketMetadata = AM.LinkPacketMetadata;
PacketLinkQuality = AM.PacketLinkQuality;
PacketTransmitPower = AM.PacketTransmitPower;
PacketRSSI = AM.PacketRSSI;


}
