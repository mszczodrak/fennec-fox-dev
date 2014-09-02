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
  * Fennec Fox cc2420 adaptation
  *
  * @author: Marcin K Szczodrak
  */

#include "cc2420.h"

configuration cc2420C {

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

uses interface PacketTimeStamp<TRadio, uint32_t> as UnimplementedPacketTimeStampRadio;
uses interface PacketTimeStamp<TMilli, uint32_t> as UnimplementedPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;

}

implementation {

components cc2420P;
components CC2420ControlC;
components CC2420ActiveMessageC as AM;

Param = cc2420P;
SplitControl = cc2420P.SplitControl;
AMQueueControl = cc2420P.AMQueueControl;

PacketLinkQuality = cc2420P.PacketLinkQuality;
PacketTransmitPower = cc2420P.PacketTransmitPower;
PacketRSSI = cc2420P.PacketRSSI;
AMSend = cc2420P;
Receive = cc2420P.Receive;
Snoop = cc2420P.Snoop;

cc2420P.CC2420Config -> CC2420ControlC;

RadioChannel = cc2420P;

PacketTimeStampRadio = UnimplementedPacketTimeStampRadio;
PacketTimeStampMilli = UnimplementedPacketTimeStampMilli;
PacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;

cc2420P.CC2420Packet -> AM.CC2420Packet;
cc2420P.SubSplitControl -> AM.SplitControl;
cc2420P.SubAMSend -> AM.AMSend;
cc2420P.SubReceive -> AM.Receive;
cc2420P.SubSnoop -> AM.Snoop;
cc2420P.AMPacket -> AM.AMPacket;

Packet = AM.Packet;
AMPacket = AM.AMPacket;
LowPowerListening = AM.LowPowerListening;
PacketAcknowledgements = AM;
LinkPacketMetadata = AM.LinkPacketMetadata;

//PacketTimeStampRadio = CC2420ActiveMessageC.PacketTimeStampRadio;
//PacketTimeStampMilli = CC2420ActiveMessageC.PacketTimeStampMilli;
//PacketTimeStamp32khz = CC2420ActiveMessageC.PacketTimeStamp32khz;

/*
PacketTimeStampRadio = cc2420P.PacketTimeStampRadio;
PacketTimeStampMilli = cc2420P.PacketTimeStampMilli;
PacketTimeStamp32khz = cc2420P.PacketTimeStamp32khz;
*/

/* System LowPowerListening Confs */
components SystemLowPowerListeningC;
cc2420P.SystemLowPowerListening -> SystemLowPowerListeningC;
cc2420P.LowPowerListening -> AM.LowPowerListening;

}
