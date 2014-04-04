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
  * Fennec Fox nullAM MAC module
  *
  * @author: Marcin K Szczodrak
  */
#include "nullAM.h"

configuration nullAMC {

provides interface SplitControl;
provides interface AMSend as MacAMSend[process_t process_id];
provides interface Receive as MacReceive[process_t process_id];
provides interface Receive as MacSnoop[process_t process_id];
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface nullAMParams;

provides interface LowPowerListening;
provides interface RadioChannel;
//provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;

//uses interface PacketTimeStamp<TRadio, uint32_t> as UnimplementedPacketTimeStampRadio;
uses interface PacketTimeStamp<TMilli, uint32_t> as UnimplementedPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;

}

implementation {

components nullAMP;

nullAMParams = nullAMP;
SplitControl = nullAMP.SplitControl;

LowPowerListening = nullAMP;
RadioChannel = nullAMP;
MacAMSend = nullAMP;
MacReceive = nullAMP.MacReceive;
MacSnoop = nullAMP.MacSnoop;
MacAMPacket = nullAMP;
MacPacket = nullAMP;
MacPacketAcknowledgements = nullAMP;
MacLinkPacketMetadata = nullAMP;

//MacPacketTimeStampRadio = UnimplementedPacketTimeStampRadio;
MacPacketTimeStampMilli = UnimplementedPacketTimeStampMilli;
MacPacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;







}

