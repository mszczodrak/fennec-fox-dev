/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox cc2420x adaptation
  *
  * @author: Marcin K Szczodrak
  */

configuration cc2420xCollisionLayerC {

provides interface StdControl;
provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface cc2420xParams;
}

implementation {

components cc2420xCollisionLayerP;
StdControl = cc2420xCollisionLayerP.StdControl;
RadioSend = cc2420xCollisionLayerP.RadioSend;
RadioReceive = cc2420xCollisionLayerP.RadioReceive;
SubSend = cc2420xCollisionLayerP.SubSend;
SubReceive = cc2420xCollisionLayerP.SubReceive;
RadioAlarm = cc2420xCollisionLayerP.RadioAlarm;
RandomCollisionConfig = cc2420xCollisionLayerP.RandomCollisionConfig;
SlottedCollisionConfig = cc2420xCollisionLayerP.SlottedCollisionConfig;
cc2420xParams = cc2420xCollisionLayerP.cc2420xParams;

/* wire to SlottedCollisionLayer */

components new SlottedCollisionLayerC();
cc2420xCollisionLayerP.SlottedRadioSend -> SlottedCollisionLayerC.RadioSend;
cc2420xCollisionLayerP.SlottedRadioReceive -> SlottedCollisionLayerC.RadioReceive;

SlottedCollisionLayerC.SubSend -> cc2420xCollisionLayerP.SlottedSubSend;
SlottedCollisionLayerC.SubReceive -> cc2420xCollisionLayerP.SlottedSubReceive;
SlottedCollisionLayerC.RadioAlarm -> cc2420xCollisionLayerP.SlottedRadioAlarm;
SlottedCollisionLayerC.Config -> cc2420xCollisionLayerP.SlottedConfig;

/* wire to RandomCollisionLayer */

components new RandomCollisionLayerC();
cc2420xCollisionLayerP.RandomRadioSend -> RandomCollisionLayerC.RadioSend;
cc2420xCollisionLayerP.RandomRadioReceive -> RandomCollisionLayerC.RadioReceive;

RandomCollisionLayerC.SubSend -> cc2420xCollisionLayerP.RandomSubSend;
RandomCollisionLayerC.SubReceive -> cc2420xCollisionLayerP.RandomSubReceive;
RandomCollisionLayerC.RadioAlarm -> cc2420xCollisionLayerP.RandomRadioAlarm;
RandomCollisionLayerC.Config -> cc2420xCollisionLayerP.RandomConfig;

}
