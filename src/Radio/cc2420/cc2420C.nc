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
  * Fennec Fox cc2420 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */

#include <Fennec.h>

generic configuration cc2420C(process_t process) {
provides interface SplitControl;
provides interface RadioReceive;

uses interface cc2420Params;

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

components new cc2420P(process);
components cc2420MultiC;

components new SimpleFcfsArbiterC("CC2420_RADIO_RESOURCE") as CC2420ResourceC;

SplitControl = cc2420P;
cc2420Params = cc2420P;
RadioReceive = cc2420MultiC.RadioReceive[process];
RadioBuffer = cc2420MultiC.RadioBuffer[process];
RadioSend = cc2420MultiC.RadioSend[process];
RadioState = cc2420P.RadioState;

RadioPacket = cc2420MultiC.RadioPacket;

RadioResource = cc2420P.RadioResource;
cc2420P.SubRadioResource -> CC2420ResourceC.Resource[process];

cc2420P.cc2420DriverParams -> cc2420MultiC.cc2420DriverParams;
cc2420P.SubRadioState -> cc2420MultiC.RadioState[process];

RadioCCA = cc2420MultiC.RadioCCA[process];

PacketTransmitPower = cc2420MultiC.PacketTransmitPower;
PacketLinkQuality = cc2420MultiC.PacketLinkQuality;
PacketRSSI = cc2420MultiC.PacketRSSI;
RadioLinkPacketMetadata = cc2420MultiC;
PacketTimeSync = cc2420MultiC.PacketTimeSync;

components LedsC;
cc2420P.Leds -> LedsC;


}
