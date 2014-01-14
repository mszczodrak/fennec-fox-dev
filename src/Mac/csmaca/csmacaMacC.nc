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
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include "csmacaMac.h"

configuration csmacaMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmacaMacParams;

uses interface RadioReceive;

uses interface Resource as RadioResource;

uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioCCA;

uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;
}

implementation {

components csmacaMacP;

SplitControl = csmacaMacP;
MacAMSend = csmacaMacP.MacAMSend;
MacReceive = csmacaMacP.MacReceive;
MacSnoop = csmacaMacP.MacSnoop;
MacPacket = csmacaMacP.MacPacket;
MacAMPacket = csmacaMacP.MacAMPacket;
MacPacketAcknowledgements = csmacaMacP.MacPacketAcknowledgements;
MacLinkPacketMetadata = csmacaMacP.MacLinkPacketMetadata;
csmacaMacParams = csmacaMacP;

RadioResource = csmacaMacP.RadioResource;
RadioPacket = csmacaMacP.RadioPacket;


RadioLinkPacketMetadata = csmacaMacP.RadioLinkPacketMetadata;

components CSMATransmitC;
RadioResource = CSMATransmitC.RadioResource;
RadioState = CSMATransmitC.RadioState;

components DefaultLplC as LplC;
csmacaMacP.RadioControl -> LplC.SplitControl;

components UniqueC;

RadioPacket = UniqueC.RadioPacket;

csmacaMacP.SubSend -> UniqueC;
csmacaMacP.SubReceive -> LplC;

// SplitControl Layers

LplC.MacPacketAcknowledgements -> csmacaMacP.MacPacketAcknowledgements;
LplC.SubControl -> CSMATransmitC;

UniqueC.SubSend -> LplC.Send;
LplC.SubSend -> CSMATransmitC;

LplC.SubReceive -> UniqueC.Receive;
UniqueC.SubReceive = RadioReceive;

RadioCCA = LplC.RadioCCA;

PacketTransmitPower = LplC.PacketTransmitPower;
PacketRSSI = LplC.PacketRSSI;
PacketTimeSync = LplC.PacketTimeSync;
PacketLinkQuality = LplC.PacketLinkQuality;


csmacaMacParams = LplC.csmacaMacParams;
csmacaMacParams = CSMATransmitC.csmacaMacParams;

components RandomC;
csmacaMacP.Random -> RandomC;

components LedsC;
csmacaMacP.Leds -> LedsC;

RadioBuffer = CSMATransmitC.RadioBuffer;
RadioSend = CSMATransmitC.RadioSend;
RadioPacket = CSMATransmitC.RadioPacket;
RadioCCA = CSMATransmitC.RadioCCA;
PacketTransmitPower = CSMATransmitC.PacketTransmitPower;
PacketRSSI = CSMATransmitC.PacketRSSI;
PacketTimeSync = CSMATransmitC.PacketTimeSync;
PacketLinkQuality = CSMATransmitC.PacketLinkQuality;

LplC.CSMATransmit -> CSMATransmitC.CSMATransmit;
}

