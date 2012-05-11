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
 * Radio Driver: UWB-Enhants
 * Author: Marcin Szczodrak
 * Date: 4/9/2011
 */



configuration eUWB01RxC {
   provides interface StdControl;
   provides interface eReceive;
}

implementation {

  components eUWB01RxP;
  StdControl = eUWB01RxP;
  eReceive = eUWB01RxP;

  components new TimerMilliC() as Timer0;
  eUWB01RxP.Timer0 -> Timer0;

  components HplAtm128GeneralIOC as GeneralIO;
  eUWB01RxP.PortC0 -> GeneralIO.PortC0;
  eUWB01RxP.PortC1 -> GeneralIO.PortC1;
  eUWB01RxP.PortC2 -> GeneralIO.PortC2;
  eUWB01RxP.PortC3 -> GeneralIO.PortC3;
  eUWB01RxP.PortC4 -> GeneralIO.PortC4;
  eUWB01RxP.PortC5 -> GeneralIO.PortC5;
  eUWB01RxP.PortC6 -> GeneralIO.PortC6;
  eUWB01RxP.PortC7 -> GeneralIO.PortC7;
  eUWB01RxP.PortA7 -> GeneralIO.PortA7;

  components HplAtm128InterruptC as Interrupt;
  eUWB01RxP.Int0 -> Interrupt.Int7;

}
