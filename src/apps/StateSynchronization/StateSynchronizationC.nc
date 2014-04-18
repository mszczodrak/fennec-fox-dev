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
  * Fennec Fox State Synchronizarion Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include "StateSynchronization.h"

generic configuration StateSynchronizationC(process_t process) {
provides interface SplitControl;

uses interface StateSynchronizationParams;
uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
}

implementation {

components new StateSynchronizationP(process);
SplitControl = StateSynchronizationP;
StateSynchronizationParams = StateSynchronizationP;

SubAMSend = StateSynchronizationP;
SubReceive = StateSynchronizationP.SubReceive;
SubSnoop = StateSynchronizationP.SubSnoop;
SubAMPacket = StateSynchronizationP.SubAMPacket;
SubPacket = StateSynchronizationP.SubPacket;
SubPacketAcknowledgements = StateSynchronizationP.SubPacketAcknowledgements;

SubPacketLinkQuality = StateSynchronizationP.SubPacketLinkQuality;
SubPacketTransmitPower = StateSynchronizationP.SubPacketTransmitPower;
SubPacketRSSI = StateSynchronizationP.SubPacketRSSI;

components FennecC;
StateSynchronizationP.FennecState -> FennecC;

components RandomC;
StateSynchronizationP.Random -> RandomC;

components LedsC;
StateSynchronizationP.Leds -> LedsC;

components new TimerMilliC() as Timer;
StateSynchronizationP.Timer -> Timer;

}

