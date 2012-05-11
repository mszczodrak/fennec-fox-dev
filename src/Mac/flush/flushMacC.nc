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
 * Application: implementation of MAC Flush protocol
 *              see "Flush: a reliable bulk transport protocol for multihop 
                wireless networks" by Kim.
 * Author: Marcin Szczodrak
 * Date: 11/25/2011
 */

#include "flushMac.h"

generic configuration flushMacC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}


implementation {
  components new flushMacP();
  Mgmt = flushMacP;
  Module = flushMacP;
  MacCall = flushMacP;
  MacSignal = flushMacP;
  RadioCall = flushMacP;
  RadioSignal = flushMacP;

  components AddressingC;
  flushMacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];

  components new TimerMilliC() as Timer0;
  flushMacP.Timer0 -> Timer0;

  components new TimerMilliC() as Timer1;
  flushMacP.Timer1 -> Timer1;

  components new QueueC(struct qe_msg, SIMPLECONTROL_QUEUE_LEN) as msgsQueue;
  flushMacP.msgsQueue->msgsQueue;

  components new QueueC(struct qe_msg, SIMPLECONTROL_QUEUE_LEN * 2) as unACKedQueue;
  flushMacP.unACKedQueue->unACKedQueue;

}

