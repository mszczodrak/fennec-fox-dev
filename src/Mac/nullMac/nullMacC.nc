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
  * Fennec Fox nullMac MAC module
  *
  * @author: Marcin K Szczodrak
  */
#include "nullMac.h"

generic configuration nullMacC(process_t process) {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface nullMacParams;
uses interface RadioReceive;

uses interface Resource as RadioResource;
uses interface SplitControl as RadioControl;
uses interface RadioPacket;
uses interface RadioBuffer;
uses interface RadioSend;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface RadioCCA;
uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;

}

implementation {

components new nullMacP(process);
SplitControl = nullMacP;
MacAMSend = nullMacP.MacAMSend;
MacReceive = nullMacP.MacReceive;
MacSnoop = nullMacP.MacSnoop;
MacPacket = nullMacP.MacPacket;
MacAMPacket = nullMacP.MacAMPacket;
MacPacketAcknowledgements = nullMacP.MacPacketAcknowledgements;
MacLinkPacketMetadata = nullMacP.MacLinkPacketMetadata;

nullMacParams = nullMacP;

RadioResource = nullMacP.RadioResource;
RadioPacket = nullMacP.RadioPacket;
RadioBuffer = nullMacP.RadioBuffer;
RadioSend = nullMacP.RadioSend;
RadioControl = nullMacP.RadioControl;
RadioReceive = nullMacP.RadioReceive;

RadioState = nullMacP.RadioState;
RadioLinkPacketMetadata = nullMacP.RadioLinkPacketMetadata;
RadioCCA = nullMacP.RadioCCA;

components RandomC;
nullMacP.Random -> RandomC;

PacketTransmitPower = nullMacP.PacketTransmitPower;
PacketRSSI = nullMacP.PacketRSSI;
PacketTimeSync = nullMacP.PacketTimeSync;
PacketLinkQuality = nullMacP.PacketLinkQuality;

components new TimerMilliC();
nullMacP.Timer -> TimerMilliC;

}

