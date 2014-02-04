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
  * Fennec Fox control MAC protocol
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/12/2012
  */



#include "cuMac.h"

configuration cuMacC {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface cuMacParams;
uses interface Receive as RadioReceive;

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

uses interface RadioState;
uses interface LinkPacketMetadata;

}

implementation {

components cuMacP;
SplitControl = cuMacP;
MacAMSend = cuMacP.MacAMSend;
MacReceive = cuMacP.MacReceive;
MacSnoop = cuMacP.MacSnoop;
MacPacket = cuMacP.MacPacket;
MacAMPacket = cuMacP.MacAMPacket;
MacPacketAcknowledgements = cuMacP.MacPacketAcknowledgements;

cuMacParams = cuMacP;

RadioConfig = cuMacP.RadioConfig;
RadioPower = cuMacP.RadioPower;
ReadRssi = cuMacP.ReadRssi;
RadioResource = cuMacP.RadioResource;
RadioPacket = cuMacP.RadioPacket;
RadioBuffer = cuMacP.RadioBuffer;
RadioSend = cuMacP.RadioSend;
RadioControl = cuMacP.RadioControl;
RadioReceive = cuMacP.RadioReceive;

EnergyIndicator = cuMacP.EnergyIndicator;
ByteIndicator = cuMacP.ByteIndicator;
PacketIndicator = cuMacP.PacketIndicator;

RadioState = cuMacP.RadioState;
LinkPacketMetadata = cuMacP.LinkPacketMetadata;


components RandomC;
cuMacP.Random -> RandomC;
components new StateC();
cuMacP.SplitControlState -> StateC;
}

