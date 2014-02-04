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
  * Fennec Fox empty MAC layer.
  *
  * @author: Marcin K Szczodrak
  */

#include "rfxMac.h"

configuration rfxMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface rfxMacParams;
uses interface RadioReceive;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface SplitControl as RadioControl;
uses interface RadioPacket;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface ReceiveIndicator as PacketIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as EnergyIndicator;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioCCA;
uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;

}

implementation {

components rfxMacP;
SplitControl = rfxMacP;
MacAMSend = rfxMacP.MacAMSend;
MacReceive = rfxMacP.MacReceive;
MacSnoop = rfxMacP.MacSnoop;
MacPacket = rfxMacP.MacPacket;
MacAMPacket = rfxMacP.MacAMPacket;
MacPacketAcknowledgements = rfxMacP.MacPacketAcknowledgements;
MacLinkPacketMetadata = rfxMacP.MacLinkPacketMetadata;

rfxMacParams = rfxMacP;

RadioConfig = rfxMacP.RadioConfig;
RadioPower = rfxMacP.RadioPower;
ReadRssi = rfxMacP.ReadRssi;
RadioResource = rfxMacP.RadioResource;
RadioPacket = rfxMacP.RadioPacket;
RadioBuffer = rfxMacP.RadioBuffer;
RadioSend = rfxMacP.RadioSend;
RadioControl = rfxMacP.RadioControl;
RadioReceive = rfxMacP.RadioReceive;

RadioState = rfxMacP.RadioState;
RadioLinkPacketMetadata = rfxMacP.RadioLinkPacketMetadata;
RadioCCA = rfxMacP.RadioCCA;

EnergyIndicator = rfxMacP.EnergyIndicator;
ByteIndicator = rfxMacP.ByteIndicator;
PacketIndicator = rfxMacP.PacketIndicator;

components RandomC;
rfxMacP.Random -> RandomC;
components new StateC();
rfxMacP.SplitControlState -> StateC;

PacketTransmitPower = rfxMacP.PacketTransmitPower;
PacketRSSI = rfxMacP.PacketRSSI;
PacketTimeSyncOffset = rfxMacP.PacketTimeSyncOffset;
PacketLinkQuality = rfxMacP.PacketLinkQuality;


components new ActiveMessageLayerC();
rfxMacP.ActiveMessageLayerAMPacket -> ActiveMessageLayerC.AMPacket;
rfxMacP.ActiveMessageLayerPacket -> ActiveMessageLayerC.Packet;
rfxMacP.ActiveMessageLayerAMSend -> ActiveMessageLayerC.AMSend[100];
rfxMacP.ActiveMessageLayerReceive -> ActiveMessageLayerC.Receive[100];
rfxMacP.ActiveMessageLayerSnoop -> ActiveMessageLayerC.Snoop[100];


ActiveMessageLayerC.SubPacket -> rfxMacP.ActiveMessageLayerRadioPacket;
ActiveMessageLayerC.BareReceive -> rfxMacP.ActiveMessageLayerBareReceive;
ActiveMessageLayerC.BareSend -> rfxMacP.ActiveMessageLayerBareSend;
ActiveMessageLayerC.ActiveMessageConfig -> rfxMacP.ActiveMessageLayerActiveMessageConfig;



components new Ieee154MessageLayerC();
Ieee154MessageLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;


rfxMacP.Ieee154PacketLayer -> Ieee154PacketLayerC;


}

