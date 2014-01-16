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
  * Cape Fox radio driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/28/2013
  */



configuration capeC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface capeParams;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

components capeP;
SplitControl = capeP;
RadioState = capeP;
capeParams = capeP;
RadioReceive = capeP.RadioReceive;

PacketTransmitPower = capeP.PacketTransmitPower;
PacketRSSI = capeP.PacketRSSI;
PacketTimeSync = capeP.PacketTimeSync;
PacketLinkQuality = capeP.PacketLinkQuality;
RadioLinkPacketMetadata = capeP.RadioLinkPacketMetadata;

RadioResource = capeP.RadioResource;

RadioBuffer = capeP.RadioBuffer;
RadioPacket = capeP.RadioPacket;
RadioSend = capeP.RadioSend;

components CapePacketModelC as CapePacketModelC;
components CpmModelC;

capeP.AMControl -> CapePacketModelC;
capeP.Model -> CapePacketModelC.Packet;

CapePacketModelC.GainRadioModel -> CpmModelC;
RadioCCA = CapePacketModelC.RadioCCA;
}
