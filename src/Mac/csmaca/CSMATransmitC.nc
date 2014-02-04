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
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include "IEEE802154.h"

generic configuration CSMATransmitC() {

provides interface CSMATransmit;
provides interface SplitControl;
provides interface Send;

uses interface StdControl as RadioStdControl;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;
uses interface csmacaParams;
uses interface Resource as RadioResource;
uses interface RadioCCA;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioState;

}

implementation {

components new CSMATransmitP();
CSMATransmit = CSMATransmitP;
RadioCCA = CSMATransmitP.RadioCCA;
RadioState = CSMATransmitP.RadioState;

RadioStdControl = CSMATransmitP.RadioStdControl;

//components new Alarm32khz32C() as Alarm;
//CSMATransmitP.BackoffTimer -> Alarm;

components new MuxAlarm32khz32C() as Alarm;
CSMATransmitP.BackoffTimer -> Alarm;


RadioBuffer = CSMATransmitP.RadioBuffer;
RadioSend = CSMATransmitP.RadioSend;
RadioPacket = CSMATransmitP.RadioPacket;

csmacaParams = CSMATransmitP.csmacaParams;

components RandomC;
CSMATransmitP.Random -> RandomC;

SplitControl = CSMATransmitP;
Send = CSMATransmitP;
RadioResource = CSMATransmitP.RadioResource;

components new StateC();
CSMATransmitP.SplitControlState -> StateC;

PacketTransmitPower = CSMATransmitP.PacketTransmitPower;
PacketRSSI = CSMATransmitP.PacketRSSI;
PacketTimeSync = CSMATransmitP.PacketTimeSync;
PacketLinkQuality = CSMATransmitP.PacketLinkQuality;

}
