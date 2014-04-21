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
  * Fennec Fox rf212 adaptation
  *
  * @author: Marcin K Szczodrak
  */

configuration rf212CollisionLayerC {

provides interface StdControl;
provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface rf212Params;

}

implementation {

components rf212CollisionLayerP;
StdControl = rf212CollisionLayerP.StdControl;
RadioSend = rf212CollisionLayerP.RadioSend;
RadioReceive = rf212CollisionLayerP.RadioReceive;
SubSend = rf212CollisionLayerP.SubSend;
SubReceive = rf212CollisionLayerP.SubReceive;
RadioAlarm = rf212CollisionLayerP.RadioAlarm;
RandomCollisionConfig = rf212CollisionLayerP.RandomCollisionConfig;
SlottedCollisionConfig = rf212CollisionLayerP.SlottedCollisionConfig;
rf212Params = rf212CollisionLayerP.rf212Params;

/* wire to SlottedCollisionLayer */

components new SlottedCollisionLayerC();
rf212CollisionLayerP.SlottedRadioSend -> SlottedCollisionLayerC.RadioSend;
rf212CollisionLayerP.SlottedRadioReceive -> SlottedCollisionLayerC.RadioReceive;

SlottedCollisionLayerC.SubSend -> rf212CollisionLayerP.SlottedSubSend;
SlottedCollisionLayerC.SubReceive -> rf212CollisionLayerP.SlottedSubReceive;
SlottedCollisionLayerC.RadioAlarm -> rf212CollisionLayerP.SlottedRadioAlarm;
SlottedCollisionLayerC.Config -> rf212CollisionLayerP.SlottedConfig;

/* wire to RandomCollisionLayer */

components new RandomCollisionLayerC();
rf212CollisionLayerP.RandomRadioSend -> RandomCollisionLayerC.RadioSend;
rf212CollisionLayerP.RandomRadioReceive -> RandomCollisionLayerC.RadioReceive;

RandomCollisionLayerC.SubSend -> rf212CollisionLayerP.RandomSubSend;
RandomCollisionLayerC.SubReceive -> rf212CollisionLayerP.RandomSubReceive;
RandomCollisionLayerC.RadioAlarm -> rf212CollisionLayerP.RandomRadioAlarm;
RandomCollisionLayerC.Config -> rf212CollisionLayerP.RandomConfig;

}
