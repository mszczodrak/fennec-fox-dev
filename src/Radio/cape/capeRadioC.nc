/*
 * Copyright (c) 2010, Columbia University.
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
  * Cape Fox simulator radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 05/23/2013
  */


configuration capeRadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface capeRadioParams;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

components capeRadioP;
SplitControl = capeRadioP;
RadioState = capeRadioP;
capeRadioParams = capeRadioP;
RadioReceive = capeRadioP.RadioReceive;

PacketTransmitPower = capeRadioP.PacketTransmitPower;
PacketRSSI = capeRadioP.PacketRSSI;
PacketTimeSyncOffset = capeRadioP.PacketTimeSyncOffset;
PacketLinkQuality = capeRadioP.PacketLinkQuality;
RadioLinkPacketMetadata = capeRadioP.RadioLinkPacketMetadata;

RadioResource = capeRadioP.RadioResource;

RadioBuffer = capeRadioP.RadioBuffer;
RadioPacket = capeRadioP.RadioPacket;
RadioSend = capeRadioP.RadioSend;

components CapePacketModelC as CapePacketModelC;
components CpmModelC;

capeRadioP.AMControl -> CapePacketModelC;
capeRadioP.Model -> CapePacketModelC.Packet;

CapePacketModelC.GainRadioModel -> CpmModelC;
RadioCCA = CapePacketModelC.RadioCCA;
}
