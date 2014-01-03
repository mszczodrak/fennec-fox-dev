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
  * cc2420 driver adapted from the TinyOS ActiveMessage stack for CC2420 and cc2420x
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


configuration cc2420RadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface cc2420RadioParams;
provides interface Resource as RadioResource;
provides interface RadioSend;
provides interface RadioPacket;
provides interface RadioBuffer;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;


}

implementation {

components cc2420RadioP;
components cc2420ControlC;
components cc2420DriverC;
cc2420RadioParams = cc2420DriverC.cc2420RadioParams;
RadioCCA = cc2420DriverC.RadioCCA;

cc2420RadioP.RadioPower -> cc2420ControlC.RadioPower;
cc2420RadioP.RadioResource -> cc2420ControlC.RadioResource;

SplitControl = cc2420RadioP;
cc2420RadioParams = cc2420RadioP;

RadioResource = cc2420ControlC.RadioResource;

cc2420RadioParams = cc2420ControlC;

cc2420RadioP.RadioConfig -> cc2420ControlC.RadioConfig;

components cc2420ReceiveC;
cc2420ReceiveC.RadioConfig -> cc2420ControlC.RadioConfig;
cc2420RadioP.ReceiveControl -> cc2420ReceiveC.StdControl;

RadioReceive = cc2420ReceiveC.RadioReceive;
RadioBuffer = cc2420DriverC.RadioBuffer;
RadioSend = cc2420DriverC.RadioSend;
RadioPacket = cc2420DriverC.RadioPacket;
cc2420RadioP.TransmitControl -> cc2420DriverC.StdControl;

cc2420ReceiveC.RadioPacket -> cc2420DriverC.RadioPacket;

components LedsC;
cc2420RadioP.Leds -> LedsC;


RadioState = cc2420RadioP.RadioState;
RadioLinkPacketMetadata = cc2420DriverC.RadioLinkPacketMetadata;
  
PacketTransmitPower = cc2420DriverC.PacketTransmitPower;
PacketRSSI = cc2420DriverC.PacketRSSI;
PacketTimeSyncOffset = cc2420DriverC.PacketTimeSyncOffset;
PacketLinkQuality = cc2420DriverC.PacketLinkQuality;

cc2420ReceiveC.PacketTimeSyncOffset -> cc2420DriverC.PacketTimeSyncOffset;

}
