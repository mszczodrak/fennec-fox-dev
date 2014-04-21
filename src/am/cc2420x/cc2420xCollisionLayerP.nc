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

#include <Tasklet.h>

module cc2420xCollisionLayerP {
provides interface StdControl;
provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface cc2420xParams;

/* wire to Slotted */
uses interface RadioSend as SlottedRadioSend;
uses interface RadioReceive as SlottedRadioReceive;

provides interface RadioSend as SlottedSubSend;
provides interface RadioReceive as SlottedSubReceive;
provides interface RadioAlarm as SlottedRadioAlarm;
provides interface SlottedCollisionConfig as SlottedConfig;


/* wire to Random */
uses interface RadioSend as RandomRadioSend;
uses interface RadioReceive as RandomRadioReceive;

provides interface RadioSend as RandomSubSend;
provides interface RadioReceive as RandomSubReceive;
provides interface RadioAlarm as RandomRadioAlarm;
provides interface RandomCollisionConfig as RandomConfig;

}

implementation {

norace bool slotted = FALSE;

command error_t StdControl.start() {
	slotted = call cc2420xParams.get_slotted();
	return SUCCESS;
}

command error_t StdControl.stop() {
	return SUCCESS;
}

tasklet_async command error_t RadioSend.send(message_t* msg) {
	if (slotted) {
		return call SlottedRadioSend.send(msg);
	} else {
		return call RandomRadioSend.send(msg);
	}
}

/*
	Sub Events
*/

tasklet_async event void SubSend.ready() {
	if (slotted) {
		return signal SlottedSubSend.ready();
	} else {
		return signal RandomSubSend.ready();
	}
}

tasklet_async event void SubSend.sendDone(error_t error) {
	if (slotted) {
		return signal SlottedSubSend.sendDone(error);
	} else {
		return signal RandomSubSend.sendDone(error);
	}
}

tasklet_async event bool SubReceive.header(message_t* msg) {
	if (slotted) {
		return signal SlottedSubReceive.header(msg);
	} else {
		return signal RandomSubReceive.header(msg);
	}
}

tasklet_async event message_t* SubReceive.receive(message_t* msg) {
	if (slotted) {
		return signal SlottedSubReceive.receive(msg);
	} else {
		return signal RandomSubReceive.receive(msg);
	}
}

tasklet_async event void RadioAlarm.fired() {
	if (slotted) {
		return signal SlottedRadioAlarm.fired();
	} else {
		return signal RandomRadioAlarm.fired();
	}
}

/* 
	Slotted Commands
*/


tasklet_async command error_t SlottedSubSend.send(message_t* msg) {
	return call SubSend.send(msg);
}

tasklet_async command bool SlottedRadioAlarm.isFree() {
	return call RadioAlarm.isFree();
}

tasklet_async command void SlottedRadioAlarm.wait(tradio_size timeout) {
	return call RadioAlarm.wait(timeout);
}

tasklet_async command void SlottedRadioAlarm.cancel() {
	return call RadioAlarm.cancel();
}

async command tradio_size SlottedRadioAlarm.getNow() {
	return call RadioAlarm.getNow();
}

async command uint16_t SlottedConfig.getInitialDelay() {
	return call SlottedCollisionConfig.getInitialDelay();
}

async command uint8_t SlottedConfig.getScheduleExponent() {
	return call SlottedCollisionConfig.getScheduleExponent();
}

async command uint16_t SlottedConfig.getTransmitTime(message_t* msg) {
	return call SlottedCollisionConfig.getTransmitTime(msg);
}

async command uint16_t SlottedConfig.getCollisionWindowStart(message_t* msg) {
	return call SlottedCollisionConfig.getCollisionWindowStart(msg);
}

async command uint16_t SlottedConfig.getCollisionWindowLength(message_t* msg) {
	return call SlottedCollisionConfig.getCollisionWindowLength(msg);
}

/*
	Slotted Events
*/

tasklet_async event void SlottedRadioSend.ready() {
	return signal RadioSend.ready();
}

tasklet_async event void SlottedRadioSend.sendDone(error_t error) {
	return signal RadioSend.sendDone(error);
}

tasklet_async event bool SlottedRadioReceive.header(message_t* msg) {
	return signal RadioReceive.header(msg);
}


tasklet_async event message_t* SlottedRadioReceive.receive(message_t* msg) {
	return signal RadioReceive.receive(msg);
}


/*
	Random Commands
*/

tasklet_async command error_t RandomSubSend.send(message_t* msg) {
	return call SubSend.send(msg);
}

tasklet_async command bool RandomRadioAlarm.isFree() {
	return call RadioAlarm.isFree();
}

tasklet_async command void RandomRadioAlarm.wait(tradio_size timeout) {
	return call RadioAlarm.wait(timeout);
}

tasklet_async command void RandomRadioAlarm.cancel() {
	return call RadioAlarm.cancel();
}

async command tradio_size RandomRadioAlarm.getNow() {
	return call RadioAlarm.getNow();
}

async command uint16_t RandomConfig.getInitialBackoff(message_t* msg) {
	return call RandomCollisionConfig.getInitialBackoff(msg);
}

async command uint16_t RandomConfig.getCongestionBackoff(message_t* msg) {
	return call RandomCollisionConfig.getCongestionBackoff(msg);
}

async command uint16_t RandomConfig.getMinimumBackoff() {
	return call RandomCollisionConfig.getMinimumBackoff();
}

async command uint16_t RandomConfig.getTransmitBarrier(message_t* msg) {
	return call RandomCollisionConfig.getTransmitBarrier(msg);;
}

/*
	Random Events
*/

tasklet_async event void RandomRadioSend.ready() {
	return signal RadioSend.ready();
}

tasklet_async event void RandomRadioSend.sendDone(error_t error) {
	return signal RadioSend.sendDone(error);
}

tasklet_async event bool RandomRadioReceive.header(message_t* msg) {
	return signal RadioReceive.header(msg);
}


tasklet_async event message_t* RandomRadioReceive.receive(message_t* msg) {
	return signal RadioReceive.receive(msg);
}




}

