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
  * cc2420 driver adapted from the TinyOS ActiveMessage stack for CC2420 and cc2420x
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


configuration cc2420MultiC {
provides interface RadioReceive[uint8_t process_id];
provides interface RadioSend[uint8_t process_id];
provides interface RadioBuffer[uint8_t process_id];

provides interface Resource as RadioResource;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

provides interface RadioPower;
provides interface RadioConfig;
provides interface StdControl as ReceiveControl;
provides interface StdControl as TransmitControl;
provides interface cc2420DriverParams;
}

implementation {

components cc2420MultiP;


components cc2420ControlC;
components cc2420DriverC;
RadioCCA = cc2420DriverC.RadioCCA;

RadioPower = cc2420ControlC.RadioPower;
RadioResource = cc2420ControlC.RadioResource;

cc2420DriverParams = cc2420DriverC.cc2420DriverParams;

//SplitControl = cc2420P;
//cc2420Params = cc2420P;

//RadioResource = cc2420ControlC.RadioResource;

//cc2420Params = cc2420ControlC;

//cc2420P.RadioConfig -> cc2420ControlC.RadioConfig;
RadioConfig = cc2420ControlC.RadioConfig;

components cc2420ReceiveC;
cc2420ReceiveC.RadioConfig -> cc2420ControlC.RadioConfig;

//cc2420P.ReceiveControl -> cc2420ReceiveC.StdControl;
ReceiveControl = cc2420ReceiveC.StdControl;

RadioReceive = cc2420MultiP.RadioReceive;
RadioSend = cc2420MultiP.RadioSend;
RadioBuffer = cc2420MultiP.RadioBuffer;

cc2420MultiP.SubRadioReceive -> cc2420ReceiveC.RadioReceive;
cc2420MultiP.SubRadioSend -> cc2420DriverC.RadioSend;
cc2420MultiP.SubRadioBuffer -> cc2420DriverC.RadioBuffer;

//RadioBuffer = cc2420DriverC.RadioBuffer;
RadioPacket = cc2420DriverC.RadioPacket;


//cc2420P.TransmitControl -> cc2420DriverC.StdControl;
TransmitControl = cc2420DriverC.StdControl;

cc2420ReceiveC.RadioPacket -> cc2420DriverC.RadioPacket;

cc2420ControlC.cc2420DriverParams -> cc2420DriverC.cc2420DriverParams;

RadioLinkPacketMetadata = cc2420DriverC.RadioLinkPacketMetadata;
  
PacketTransmitPower = cc2420DriverC.PacketTransmitPower;
PacketRSSI = cc2420DriverC.PacketRSSI;
PacketTimeSync = cc2420DriverC.PacketTimeSync;
PacketLinkQuality = cc2420DriverC.PacketLinkQuality;

cc2420ReceiveC.PacketTimeSync -> cc2420DriverC.PacketTimeSync;

}
