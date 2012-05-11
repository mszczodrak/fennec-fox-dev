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

#include <Fennec.h>
#include "eUWB01Radio.h"

module eUWB01RxP {

  provides interface StdControl;
  provides interface eReceive;
  uses interface Timer<TMilli> as Timer0;

  uses interface GeneralIO as PortC0;
  uses interface GeneralIO as PortC1;
  uses interface GeneralIO as PortC2;
  uses interface GeneralIO as PortC3;
  uses interface GeneralIO as PortC4;
  uses interface GeneralIO as PortC5;
  uses interface GeneralIO as PortC6;
  uses interface GeneralIO as PortC7;
  uses interface GeneralIO as PortA7;
  uses interface HplAtm128Interrupt as Int0;   //interrupt for clock input
}

implementation {

  msg_t *message;
  uint8_t incomming_lenght;

  task void signal_receive();

  event void Timer0.fired() {

  }

  command error_t StdControl.start() {
    atomic {
      message = nextMessage();
      message->len = 0;
      incomming_lenght = 0;
    }

    call PortC0.makeInput();
    call PortC1.makeInput();
    call PortC2.makeInput();
    call PortC3.makeInput();
    call PortC4.makeInput();
    call PortC5.makeInput();
    call PortC6.makeInput();
    call PortC7.makeInput();

    call PortA7.makeOutput();
    call PortA7.clr();

    call Int0.clear();
    call Int0.edge(TRUE);
    call Int0.enable();

    return SUCCESS;
  }

  command error_t StdControl.stop() {

    call Int0.disable();
    call Timer0.stop();
    drop_message(message);
    return SUCCESS;
  }

  async event void Int0.fired() {
    atomic { 
      message->data[incomming_lenght] = PINC; 
      incomming_lenght++;
    }

    /* Read firts byte, save it since this is the lenght of message */
    if (incomming_lenght == sizeof(uint8_t) * 8) { // Read first 8 bits
      memcpy(&message->len, message->data, sizeof(uint8_t));
    } 

    if (incomming_lenght == message->len) {
      /* end of message */ 
      post signal_receive();
    }
  }

  task void signal_receive() {
    msg_t *new_msg = message;
    atomic {
      message = nextMessage();
      message->len = 0;
      incomming_lenght = 0;
    }
    signal eReceive.receive( new_msg );  
  }

}
