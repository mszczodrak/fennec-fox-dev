/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Low Power Listening for the CC2420
 * @author David Moss
 */


#include "DefaultLpl.h"
//#warning "*** USING DEFAULT LOW POWER COMMUNICATIONS ***"

configuration DefaultLplC {
provides interface LowPowerListening;
provides interface Send;
provides interface Receive;
provides interface SplitControl;
provides interface State as SendState;
  
uses interface Send as SubSend;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;

uses interface csmacaMacParams;
uses interface CSMATransmit;

uses interface ReceiveIndicator as PacketIndicator;
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;

}

implementation {
components DefaultLplP,
      RandomC,
      new StateC() as SendStateC,
      new TimerMilliC() as OffTimerC,
      new TimerMilliC() as OnTimerC,
      new TimerMilliC() as SendDoneTimerC,
      LedsC;
  
LowPowerListening = DefaultLplP;
Send = DefaultLplP;
Receive = DefaultLplP;
SplitControl = DefaultLplP;
SendState = SendStateC;
MacPacketAcknowledgements = DefaultLplP.PacketAcknowledgements;

CSMATransmit = DefaultLplP.CSMATransmit;

csmacaMacParams = DefaultLplP.csmacaMacParams;
SubControl = DefaultLplP.SubControl;
SubReceive = DefaultLplP.SubReceive;
SubSend = DefaultLplP.SubSend;
  
  
DefaultLplP.SendState -> SendStateC;
DefaultLplP.OffTimer -> OffTimerC;
DefaultLplP.OnTimer -> OnTimerC;
DefaultLplP.SendDoneTimer -> SendDoneTimerC;
DefaultLplP.Random -> RandomC;
DefaultLplP.Leds -> LedsC;

PacketIndicator = DefaultLplP.PacketIndicator;
EnergyIndicator = DefaultLplP.EnergyIndicator;
ByteIndicator = DefaultLplP.ByteIndicator;

}
