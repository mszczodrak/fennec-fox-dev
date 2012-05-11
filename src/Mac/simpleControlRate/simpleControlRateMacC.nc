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
 * Application: implementation of simple MAC protocol, just sends with addressing
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include "simpleControlRateMac.h"

configuration simpleControlRateMacC{
  provides interface Mgmt;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}


implementation {
  components simpleControlRateMacP;
  Mgmt = simpleControlRateMacP;
  MacCall = simpleControlRateMacP;
  MacSignal = simpleControlRateMacP;
  RadioCall = simpleControlRateMacP;
  RadioSignal = simpleControlRateMacP;

  components AddressingC;
  simpleControlRateMacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];

  components new TimerMilliC() as Timer0;
  simpleControlRateMacP.Timer0 -> Timer0;

  components new TimerMilliC() as Timer1;
  simpleControlRateMacP.Timer1 -> Timer1;

  components new QueueC(struct qe_msg, SIMPLECONTROL_QUEUE_LEN) as msgsQueue;
  simpleControlRateMacP.msgsQueue->msgsQueue;

  components new QueueC(struct qe_msg, SIMPLECONTROL_QUEUE_LEN * 2) as unACKedQueue;
  simpleControlRateMacP.unACKedQueue->unACKedQueue;

}

