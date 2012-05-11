/*
 * Copyright (c) 2011 Columbia University.
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
 * Author: Marcin Szczodrak
 * Date: 1/22/2011
 */

#include <Fennec.h>

configuration basicp2pNetC {
  provides interface Mgmt;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  components basicp2pNetP;
  Mgmt = basicp2pNetP;
  NetworkCall = basicp2pNetP;
  NetworkSignal = basicp2pNetP;
  MacCall = basicp2pNetP;
  MacSignal = basicp2pNetP;

  components AddressingC;
  basicp2pNetP.Addressing -> AddressingC.Addressing[F_NETWORK_ADDRESSING];

  components FennecFunctionsC;
  basicp2pNetP.FennecStatus -> FennecFunctionsC;

  components new TimerMilliC() as Timer0;
  basicp2pNetP.Timer0 -> Timer0;
  components new TimerMilliC() as Timer1;
  basicp2pNetP.Timer1 -> Timer1;
  components new TimerMilliC() as Timer2;
  basicp2pNetP.Timer2 -> Timer2;

  components LedsC;
  basicp2pNetP.Leds -> LedsC;

  components RandomC;
  basicp2pNetP.Random -> RandomC;

}
