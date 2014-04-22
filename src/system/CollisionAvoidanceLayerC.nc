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
  * Fennec Fox CollisionAvoidanceLayer for rfxlink
  *
  * @author: Marcin K Szczodrak
  */

generic configuration CollisionAvoidanceLayerC() {

provides interface StdControl;
provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface CollisionAvoidanceConfig;
}

implementation {

components new CollisionAvoidanceLayerP();
StdControl = CollisionAvoidanceLayerP.StdControl;
RadioSend = CollisionAvoidanceLayerP.RadioSend;
RadioReceive = CollisionAvoidanceLayerP.RadioReceive;
SubSend = CollisionAvoidanceLayerP.SubSend;
SubReceive = CollisionAvoidanceLayerP.SubReceive;
RadioAlarm = CollisionAvoidanceLayerP.RadioAlarm;
RandomCollisionConfig = CollisionAvoidanceLayerP.RandomCollisionConfig;
SlottedCollisionConfig = CollisionAvoidanceLayerP.SlottedCollisionConfig;
CollisionAvoidanceConfig = CollisionAvoidanceLayerP.CollisionAvoidanceConfig;

/* wire to SlottedCollisionLayer */

components new SlottedCollisionLayerC();
CollisionAvoidanceLayerP.SlottedRadioSend -> SlottedCollisionLayerC.RadioSend;
CollisionAvoidanceLayerP.SlottedRadioReceive -> SlottedCollisionLayerC.RadioReceive;

SlottedCollisionLayerC.SubSend -> CollisionAvoidanceLayerP.SlottedSubSend;
SlottedCollisionLayerC.SubReceive -> CollisionAvoidanceLayerP.SlottedSubReceive;
SlottedCollisionLayerC.RadioAlarm -> CollisionAvoidanceLayerP.SlottedRadioAlarm;
SlottedCollisionLayerC.Config -> CollisionAvoidanceLayerP.SlottedConfig;

/* wire to RandomCollisionLayer */

components new RandomCollisionLayerC();
CollisionAvoidanceLayerP.RandomRadioSend -> RandomCollisionLayerC.RadioSend;
CollisionAvoidanceLayerP.RandomRadioReceive -> RandomCollisionLayerC.RadioReceive;

RandomCollisionLayerC.SubSend -> CollisionAvoidanceLayerP.RandomSubSend;
RandomCollisionLayerC.SubReceive -> CollisionAvoidanceLayerP.RandomSubReceive;
RandomCollisionLayerC.RadioAlarm -> CollisionAvoidanceLayerP.RandomRadioAlarm;
RandomCollisionLayerC.Config -> CollisionAvoidanceLayerP.RandomConfig;

}
