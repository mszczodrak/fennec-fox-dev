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
  * Fennec Fox empty radio driver
  *
  * @author: Marcin K Szczodrak
  */


configuration nullRadioC {
provides interface SplitControl;
provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;
provides interface RadioReceive;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

uses interface nullRadioParams;
}

implementation {

components nullRadioP;
SplitControl = nullRadioP;
nullRadioParams = nullRadioP;
RadioReceive = nullRadioP.RadioReceive;

RadioResource = nullRadioP.RadioResource;

RadioBuffer = nullRadioP.RadioBuffer;
RadioPacket = nullRadioP.RadioPacket;
RadioSend = nullRadioP.RadioSend;

RadioState = nullRadioP.RadioState;
RadioLinkPacketMetadata = nullRadioP.RadioLinkPacketMetadata;
RadioCCA = nullRadioP.RadioCCA;

PacketTransmitPower = nullRadioP.PacketTransmitPower;
PacketRSSI = nullRadioP.PacketRSSI;
PacketTimeSyncOffset = nullRadioP.PacketTimeSyncOffset;
PacketLinkQuality = nullRadioP.PacketLinkQuality;



}
