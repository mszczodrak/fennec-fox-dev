/*
 * Copyright (c) 2009-2011 Columbia University.
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
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Application: Fennec Fox Control Unit
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */


#include <Fennec.h>

configuration ControlUnitC {
  provides interface SimpleStart;

  uses interface AMSend as MacAMSend;
  uses interface Receive as MacReceive;
  uses interface Receive as MacSnoop;
  uses interface AMPacket as MacAMPacket;
  uses interface Packet as MacPacket;
  uses interface PacketAcknowledgements as MacPacketAcknowledgements;
  uses interface ModuleStatus as MacStatus;
}

implementation {
 
  components ControlUnitP;
  SimpleStart = ControlUnitP;

  MacAMSend = ControlUnitP;
  MacReceive = ControlUnitP.MacReceive;
  MacSnoop = ControlUnitP.MacSnoop;
  MacAMPacket = ControlUnitP.MacAMPacket;
  MacPacket = ControlUnitP.MacPacket;
  MacPacketAcknowledgements = ControlUnitP.MacPacketAcknowledgements;
  MacStatus = ControlUnitP.MacStatus;

  components FennecEngineC;
  ControlUnitP.FennecEngine -> FennecEngineC;

  components CachesC;
  ControlUnitP.EventCache -> CachesC;
  ControlUnitP.PolicyCache -> CachesC;

  components RandomC;
  ControlUnitP.Random -> RandomC;

  components new TimerMilliC() as Timer;
  ControlUnitP.Timer -> Timer;
}

