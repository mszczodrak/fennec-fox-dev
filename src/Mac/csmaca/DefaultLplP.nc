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

#include "Lpl.h"
#include "DefaultLpl.h"
#include "AM.h"

module DefaultLplP {
provides interface LowPowerListening;
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
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as PacketIndicator;
uses interface csmacaMacParams;
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

task void detected();
  
void initializeSend();
void startOffTimer();


/** The current period of the duty cycle, equivalent of wakeup interval */
uint16_t sleepInterval = LPL_DEF_LOCAL_WAKEUP;

/** The number of times the CCA has been sampled in this wakeup period */
uint16_t ccaChecks;


/***************** Prototypes ****************/
task void powerStopRadio();
task void powerStartRadio();
task void getCca();

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

	if (TOS_NODE_ID == call csmacaMacParams.get_sink_addr()) {
		sleepInterval = 0;
	} else {
		sleepInterval = call csmacaMacParams.get_delay_after_receive();
	}

	if(sleepInterval > 0) {
		// Begin duty cycling
		post powerStopRadio();
		return SUCCESS;
	} else {
		post powerStartRadio();
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
	post powerStopRadio();
	return SUCCESS;
}


/***************** Timer Events ****************/
event void OnTimer.fired() {
	if(isDutyCycling()) {
		if(radioPowerState) {
			// Someone else turned on the radio, try again in awhile
			call OnTimer.startOneShot(sleepInterval);
		} else {
			ccaChecks = 0;

			/*
        		 * Turn on the radio only after the uC is fully awake.  ATmega128's
	        	 * have this issue when running on an external crystal.
	        	 */
			post getCca();

		}
	}
}


/***************** Tasks ****************/
task void powerStopRadio() {
	error_t error = call SubControl.stop();
	if(error != SUCCESS) {
		// Already stopped?
		finishSplitControlRequests();
		call OnTimer.startOneShot(sleepInterval);
	}
}

task void powerStartRadio() {
	error_t startResult = call SubControl.start();
	// If the radio wasn't started successfully, or already on, try again
	if ((startResult != SUCCESS && startResult != EALREADY)) {
		post powerStartRadio();
	}
}

task void getCca() {
	uint8_t detects = 0;
	if(isDutyCycling()) {

		ccaChecks++;
		if(ccaChecks == 1) {
			// Microcontroller is ready, turn on the radio and sample a few times
			post powerStartRadio();
			return;
		}

		atomic {
			for( ; ccaChecks < MAX_LPL_CCA_CHECKS && call SendState.isIdle(); ccaChecks++) {
				if(call PacketIndicator.isReceiving()) {
					post detected();
					return;
				}
	
				if(call EnergyIndicator.isReceiving()) {
					detects++;
					if(detects > MIN_SAMPLES_BEFORE_DETECT) {
						post detected();
						return;
					}
					// Leave the radio on for upper layers to perform some transaction
				}
			}
		}

		if(call SendState.isIdle()) {
			post powerStopRadio();
		}
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


/***************** LowPowerListening Commands ***************/
/**
 * Set this this node's radio wakeup interval, in milliseconds.
 * Once every interval, the node will sleep and perform an Rx check 
 * on the radio.  Setting the wakeup interval to 0 will keep the radio
 * always on.
 *
 * @param intervalMs the length of this node's wakeup interval, in [ms]
 */
command void LowPowerListening.setLocalWakeupInterval(uint16_t sleepIntervalMs) {

	if (!sleepInterval && sleepIntervalMs) {
		// We were always on, now lets duty cycle
		post powerStopRadio();  // Might want to delay turning off the radio
	}

	sleepInterval = sleepIntervalMs;

	if(sleepInterval == 0 && (state == S_STARTED)) {
		/*
		* Leave the radio on permanently if sleepInterval == 0 and the radio is
		* supposed to be enabled
		*/
		if(!radioPowerState) {
			call SubControl.start();
		}
	}
}
  
/**
 * @return the local node's wakeup interval, in [ms]
 */
command uint16_t LowPowerListening.getLocalWakeupInterval() {
	return sleepInterval;
}
  
/**
 * Configure this outgoing message so it can be transmitted to a neighbor mote
 * with the specified wakeup interval.
 * @param msg Pointer to the message that will be sent
 * @param intervalMs The receiving node's wakeup interval, in [ms]
 */
command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, 
	uint16_t intervalMs) {
	metadata_t *metadata = (metadata_t*) msg->metadata;
	metadata->rxInterval = intervalMs;
}
  
/**
  * @return the destination node's wakeup interval configured in this message
  */
command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
	metadata_t *metadata = (metadata_t*) msg->metadata;
	return metadata->rxInterval;
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
	dbg("Mac", "csmaMac DefaultLplP Send.send(0x%1x, %d)", msg, len);

	if(state == S_STOPPED) {
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
			initializeSend();
			return SUCCESS;
		} else {
			post startRadio();
		}
		return SUCCESS;
	}
	return EBUSY;
}

command error_t Send.cancel(message_t *msg) {
	dbg("Mac", "csmaMac DefaultLplP Send.cancel(0x%1x)", msg);
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
  
  
/***************** DutyCycle Events ***************/
/**
  * A transmitter was detected.  You must now take action to
  * turn the radio off when the transaction is complete.
  */
task void detected() {
	// At this point, the duty cycling has been disabled temporary
	// and it will be this component's job to turn the radio back off
	// Wait long enough to see if we actually receive a packet, which is
	// just a little longer in case there is more than one lpl transmitter on
	// the channel.
	startOffTimer();
}
  
  
/***************** SubControl Events ***************/
event void SubControl.startDone(error_t error) {
	dbg("Mac", "csmaMac DefaultLplP SubControl.startDone(%d)", error);
	if(!error) {
		radioPowerState = TRUE;

		if(finishSplitControlRequests()) {

		} else if(isDutyCycling()) {
			post getCca();
		}

    
		if(call SendState.getState() == S_LPL_FIRST_MESSAGE
			|| call SendState.getState() == S_LPL_SENDING) {
			initializeSend();
		}
	}
}
    
event void SubControl.stopDone(error_t error) {
	dbg("Mac", "csmaMac DefaultLplP SubControl.stopDone(%d)", error);
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
			dbg("Mac", "csmaMac DefaultLplP SubControl.startDone - force radio back");
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
	dbg("Mac", "csmaMac DefaultLplP SubSend.sendDone(0x%1x, %d)", msg, error);
   
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
event message_t *SubReceive.receive(message_t* msg, void* payload, 
      uint8_t len) {
    startOffTimer();
    return signal Receive.receive(msg, payload, len);
}
  
/***************** Timer Events ****************/
event void OffTimer.fired() {    
	dbg("Mac", "csmaMac DefaultLplP OffTimer.fired()");
    /*
     * Only stop the radio if the radio is supposed to be off permanently
     * or if the duty cycle is on and our sleep interval is not 0
     */
    if(state == S_STOPPED
        || (sleepInterval > 0
            && state != S_STOPPED
                && call SendState.getState() == S_LPL_NOT_SENDING)) { 
      post stopRadio();
    }
}



  
/**
  * When this timer is running, that means we're sending repeating messages
  * to a node that is receive check duty cycling.
  */
event void SendDoneTimer.fired() {
	dbg("Mac", "csmaMac DefaultLplP SendDoneTimer.fired()");
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
  
task void startRadio() {
	dbg("Mac", "DefaultLplP startRadio");
    	//dbgs(F_MAC, S_NONE, DBGS_RADIO_START_V_REG, 0, 0);
	//printf("mac start\n");
	//printfflush();
	if(call SubControl.start() != SUCCESS) {
		post startRadio();
	}
}
  
task void stopRadio() {
	dbg("Mac", "DefaultLplP stopRadio");
	if(call SendState.getState() == S_LPL_NOT_SENDING) {
    		//dbgs(F_MAC, S_NONE, DBGS_RADIO_STOP_V_REG, 0, 0);
		//printf("mac stop\n");
		//printfflush();
		if(call SubControl.stop() != SUCCESS) {
			post stopRadio();
		}
	}
}
  
/***************** Functions ***************/
void initializeSend() {
    if(call LowPowerListening.getRemoteWakeupInterval(currentSendMsg) > 0) {
      csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(currentSendMsg, sizeof(csmaca_header_t)); 
      if(header->dest == IEEE154_BROADCAST_ADDR) {
        call PacketAcknowledgements.noAck(currentSendMsg);
      } else {
        // Send it repetitively within our transmit window
        call PacketAcknowledgements.requestAck(currentSendMsg);
      }

      call SendDoneTimer.startOneShot(
          call LowPowerListening.getRemoteWakeupInterval(currentSendMsg) + 20);
    }
        
    post send();
}
  
  
void startOffTimer() {
    call OffTimer.startOneShot(call csmacaMacParams.get_delay_after_receive());
}

}

