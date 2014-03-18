/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Low Power Listening for the CC2420.  This component is responsible for
 * delivery of an LPL packet, and for turning off the radio when the radio
 * has run out of tasks.
 *
 * @author David Moss
 */

/*
 * Copyright (c) 2009, Columbia University.
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
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include "Lpl.h"
#include "DefaultLpl.h"
#include "AM.h"

generic module DefaultLplP(process_t process) {
provides interface Send;
provides interface Receive;
provides interface SplitControl;
  
uses interface Send as SubSend;
uses interface CSMATransmit;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;
uses interface PacketAcknowledgements;
uses interface State as SendState;
uses interface Timer<TMilli> as OffTimer;
uses interface Timer<TMilli> as OnTimer;
uses interface Timer<TMilli> as SendDoneTimer;
uses interface Random;
uses interface Leds;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioCCA;
uses interface csmacaParams;
}

implementation {
  
/** The message currently being sent */
norace message_t *currentSendMsg;
  
/** The length of the current send message */
uint8_t currentSendLen;
  
/** TRUE if the radio is duty cycling and not always on */
bool dutyCycling = FALSE;

bool radioPowerState = FALSE;

uint8_t state = S_STOPPED;


/***************** Prototypes ***************/
task void send();
task void resend();
task void startRadio();
task void stopRadio();

void startOffTimer();

/** The current period of the duty cycle, equivalent of wakeup interval */
uint16_t sleepInterval = LPL_DEF_LOCAL_WAKEUP;

bool finishSplitControlRequests();
bool isDutyCycling();


/***************** SplitControl Commands ****************/
command error_t SplitControl.start() {
	if( state == S_STARTED) {
		return EALREADY;
	} else if( state == S_STARTING) {
		return SUCCESS;
	} else if(state != S_STOPPED) {
		return EBUSY;
	}

	// Radio was off, now has been told to turn on or duty cycle.
	state = S_STARTING;

	if (TOS_NODE_ID == call csmacaParams.get_sink_addr()) {
		sleepInterval = 0;
	} else {
		sleepInterval = call csmacaParams.get_delay_after_receive();
	}

	if(sleepInterval > 0) {
		// Begin duty cycling
		post stopRadio();
		return SUCCESS;
	} else {
		post startRadio();
		return SUCCESS;
	}
}

command error_t SplitControl.stop() {
	if(state == S_STOPPED) {
		return EALREADY;
	} else if(state == S_STOPPING) {
		return SUCCESS;
	} else if(state != S_STARTED) {
		return EBUSY;
	}

	state = S_STOPPING;
	post stopRadio();
	return SUCCESS;
}


/***************** Timer Events ****************/
event void OnTimer.fired() {
	if(isDutyCycling()) {
		if(radioPowerState) {
			// Someone else turned on the radio, try again in awhile
			call OnTimer.startOneShot(sleepInterval);
		} else {

			/*
        		 * Turn on the radio only after the uC is fully awake.  ATmega128's
	        	 * have this issue when running on an external crystal.
	        	 */
			post startRadio();
		}
	}
}


/***************** Tasks ****************/
task void stopRadio() {
	if (call SubControl.stop() != SUCCESS) {
		finishSplitControlRequests();
		call OnTimer.startOneShot(sleepInterval);
	}
}


task void startRadio() {
	error_t startResult = call SubControl.start();
	if ((startResult != SUCCESS && startResult != EALREADY)) {
                post startRadio();
        }
}


/**
 * @return TRUE if the radio should be actively duty cycling
 */
bool isDutyCycling() {
	return sleepInterval > 0 && (state == S_STARTED);
}


/**
 * @return TRUE if we successfully handled a SplitControl request
 */
bool finishSplitControlRequests() {
	if( state == S_STOPPING) {
		state = S_STOPPED;
		signal SplitControl.stopDone(SUCCESS);
		return TRUE;

	} else if(state == S_STARTING) {
		// Starting while we're duty cycling first turns off the radio
		state = S_STARTED;
		signal SplitControl.startDone(SUCCESS);
		return TRUE;
	}

	return FALSE;
}


/***************** Send Commands ***************/
/**
 * Each call to this send command gives the message a single
 * DSN that does not change for every copy of the message
 * sent out.  For messages that are not acknowledged, such as
 * a broadcast address message, the receiving end does not
 * signal receive() more than once for that message.
 */
command error_t Send.send(message_t *msg, uint8_t len) {

	if(state == S_STOPPED) {
		dbg("Mac", "[%d] csmaca DefaultLplP Send.send(0x%1x, %d) - EOFF", process, msg, len);
		// Everything is off right now, start SplitControl and try again
		return EOFF;
	}
    
	 if(call SendState.requestState(S_LPL_SENDING) == SUCCESS) {
		currentSendMsg = msg;
		currentSendLen = len;
      
		// In case our off timer is running...
		call OffTimer.stop();
		call SendDoneTimer.stop();
      
		if(radioPowerState) {
			dbg("Mac", "[%d] csmaca DefaultLplP Send.send(0x%1x, %d)", process, msg, len);
			post send();
			return SUCCESS;
		} else {
			dbg("Mac", "[%d] csmaca DefaultLplP Send.send(0x%1x, %d) - startRadio", process, msg, len);
			post startRadio();
			}
		return SUCCESS;
	}
	dbg("Mac", "[%d] csmaca DefaultLplP Send.send(0x%1x, %d) - EBUSY", process, msg, len);
	return EBUSY;
}

command error_t Send.cancel(message_t *msg) {
	dbg("Mac", "[%d] csmaca DefaultLplP Send.cancel(0x%1x)", process, msg);
	if(currentSendMsg == msg) {
		call SendState.toIdle();
		call SendDoneTimer.stop();
		startOffTimer();
		return call SubSend.cancel(msg);
	}
	return FAIL;
}
  
command uint8_t Send.maxPayloadLength() {
	return call SubSend.maxPayloadLength();
}

command void *Send.getPayload(message_t* msg, uint8_t len) {
	return call SubSend.getPayload(msg, len);
}
 

task void check() {

	uint16_t i = 0;

	for( ; i < MAX_LPL_CCA_CHECKS && call SendState.isIdle(); i++) {
		if(call RadioCCA.request() == EBUSY) {
			startOffTimer();
			return;
		}
	}
	
	if(call SendState.isIdle()) {
		post stopRadio();
	}
}
 
  
/***************** SubControl Events ***************/
event void SubControl.startDone(error_t error) {
	dbg("Mac", "[%d] csmaca DefaultLplP SubControl.startDone(%d)", process, error);
	if(!error) {
		radioPowerState = TRUE;

		if(finishSplitControlRequests()) {

		} else if(isDutyCycling()) {
			post check();
		}
    
		if(call SendState.getState() == S_LPL_FIRST_MESSAGE
			|| call SendState.getState() == S_LPL_SENDING) {
			post send();
		}
	}
}
    
event void SubControl.stopDone(error_t error) {
	dbg("Mac", "[%d] csmaca DefaultLplP SubControl.stopDone(%d)", process, error);
	if(!error) {
		radioPowerState = FALSE;

		if(finishSplitControlRequests()) {
	
		} else if(isDutyCycling()) {
			call OnTimer.startOneShot(sleepInterval);
		}

		if(call SendState.getState() == S_LPL_FIRST_MESSAGE
	        	  || call SendState.getState() == S_LPL_SENDING) {
			// We're in the middle of sending a message; start the radio back up
			/** TODO:
 			temporarly we comment out the forcing radio on
			dbg("Mac", "[%d] csmaca DefaultLplP SubControl.startDone - force radio back", process);
			post startRadio();
			*/
		} else {        
			call OffTimer.stop();
			call SendDoneTimer.stop();
		}
	}
}
  
/***************** SubSend Events ***************/
event void SubSend.sendDone(message_t* msg, error_t error) {
	dbg("Mac", "[%d] csmaca DefaultLplP SubSend.sendDone(0x%1x, %d)", process, msg, error);
   
	switch(call SendState.getState()) {
	case S_LPL_SENDING:
		if(call SendDoneTimer.isRunning()) {
			if(!call PacketAcknowledgements.wasAcked(msg)) {
				post resend();
				return;
			}
		}
		break;
      
	case S_LPL_CLEAN_UP:
	/**
	* We include this state so upper layers can't send a different message
	* before the last message gets done sending
	*/
		break;
      
	default:
		break;
	}  
    
	call SendState.toIdle();
	call SendDoneTimer.stop();
	startOffTimer();
	signal Send.sendDone(msg, error);
}
  
/***************** SubReceive Events ***************/
/**
 * If the received message is new, we signal the receive event and
 * start the off timer.  If the last message we received had the same
 * DSN as this message, then the chances are pretty good
 * that this message should be ignored, especially if the destination address
 * as the broadcast address
 */
event message_t *SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	startOffTimer();
	return signal Receive.receive(msg, payload, len);
}
  
/***************** Timer Events ****************/
event void OffTimer.fired() {    
	dbg("Mac", "[%d] csmaca DefaultLplP OffTimer.fired()", process);
	/*
	* Only stop the radio if the radio is supposed to be off permanently
	* or if the duty cycle is on and our sleep interval is not 0
	*/
	if(state == S_STOPPED || (sleepInterval > 0 && state != S_STOPPED && call SendState.getState() == S_LPL_NOT_SENDING)) { 
		post stopRadio();
	}
}



  
/**
  * When this timer is running, that means we're sending repeating messages
  * to a node that is receive check duty cycling.
  */
event void SendDoneTimer.fired() {
	dbg("Mac", "[%d] csmaca DefaultLplP SendDoneTimer.fired()", process);
	if(call SendState.getState() == S_LPL_SENDING) {
		// The next time SubSend.sendDone is signaled, send is complete.
		call SendState.forceState(S_LPL_CLEAN_UP);
	}
}
  
/***************** Tasks ***************/
task void send() {
	if(call SubSend.send(currentSendMsg, currentSendLen) != SUCCESS) {
		post send();
	}
}
  
task void resend() {
	if(call CSMATransmit.resend(currentSendMsg, TRUE) != SUCCESS) {
		post resend();
	}
}
  
  
  
void startOffTimer() {
	call OffTimer.startOneShot(call csmacaParams.get_delay_after_receive());
}


async event void RadioCCA.done(error_t err) {

}

}

