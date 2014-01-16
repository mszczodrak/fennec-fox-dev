/*
 * Copyright (c) 2009 Columbia University.
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
 * author: Marcin Szczodrak
 * date: 10/10/2009
 */

#include <Fennec.h>

generic module LightEventP()
{
  provides interface Event;
  provides interface LightEvent;

  uses interface Timer<TMilli>;

  uses interface Read<uint16_t> as Light;
}

implementation {

  uint16_t threshold;
  uint8_t op;
  bool occures;

  command void Event.start(nx_struct fennec_event *en) {
    occures = FALSE;
    threshold = en->value;
    op = en->operation; 
    call Timer.startPeriodic(DEFAULT_FENNEC_SENSE_PERIOD);
  }

  command void Event.stop() {
    call Timer.stop();
  }

  command void LightEvent.setFrequency(uint16_t ms_delay) {
    call Timer.startPeriodic(ms_delay);
  }

  command void LightEvent.setOperation(uint8_t new_op) {
    op = new_op;
  }

  command void LightEvent.setThreshold(uint16_t value) {
    threshold = value;
  }

  event void Timer.fired() {
    if (call Light.read() == SUCCESS) {
    } else {
    }
  }


  event void Light.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {

      switch(op) {

        case EQ:
          if (val == threshold) {
            if (!occures) {
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        case NQ:
          if (val != threshold) {
            if (!occures) {           
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        case LT:
          if (val < threshold) {
            if (!occures) {
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        case LE:
          if (val <= threshold) {
            if (!occures) {
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        case GT:
          if (val > threshold) {
            if (!occures) {
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        case GE:
          if (val >= threshold) {
            if (!occures) {
              occures = TRUE;
              signal Event.occured(TRUE);
            }
          } else {
            if (occures) {
              occures = FALSE;
              signal Event.occured(FALSE);
            }
          }
          break;

        default:
          break;
      }
    } else {
      occures = FALSE;
      signal Event.occured(FALSE);
    }
  }
}



