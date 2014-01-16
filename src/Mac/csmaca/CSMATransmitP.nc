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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
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

#include "crc.h"
#include "message.h"
#include "Fennec.h"
#include "csmaca.h"

module CSMATransmitP @safe() {
provides interface CSMATransmit;
provides interface SplitControl;
provides interface Send;

uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
uses interface RadioCCA;
uses interface StdControl as RadioStdControl;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;
uses interface csmacaParams;
uses interface Random;
uses interface State as SplitControlState;
uses interface Resource as RadioResource;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioState;
}

implementation {

norace message_t * ONE_NOK m_msg;
norace bool m_cca;
norace uint8_t m_state = S_STOPPED;
norace uint16_t csmaca_backoff_period;
norace uint16_t csmaca_min_backoff;
norace uint16_t csmaca_delay_after_receive;

norace error_t sendDoneErr;

enum {
	S_STOPPED,
	S_STARTING,
	S_STARTED,
	S_STOPPING,
	S_TRANSMITTING,
};

error_t sendErr = SUCCESS;

/** TRUE if we are to use CCA when sending the current packet */
norace bool ccaOn;

/****************** Prototypes ****************/
task void startDone_task();
task void stopDone_task();
task void sendDone_task();

void shutdown();

task void signalSendDone() {
	m_state = S_STARTED;
	atomic sendErr = sendDoneErr;
	post sendDone_task();
}

/** Total CCA checks that showed no activity before the NoAck LPL send */
norace int8_t totalCcaChecks;
  
/** The initial backoff period */
norace uint16_t myInitialBackoff;
  
/** The congestion backoff period */
norace uint16_t myCongestionBackoff;


/***************** SplitControl Commands ****************/
command error_t SplitControl.start() {
	if(call SplitControlState.requestState(S_STARTING) == SUCCESS) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.start()");
		return call RadioState.turnOn();
	} else if(call SplitControlState.isState(S_STARTED)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.start() - S_STARTED");
		return EALREADY;

	} else if(call SplitControlState.isState(S_STARTING)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.start() - S_STARTING");
		return SUCCESS;
	}

	return EBUSY;
}

command error_t SplitControl.stop() {
	if (call SplitControlState.isState(S_STARTED)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.stop() - S_STARTED");
		call SplitControlState.forceState(S_STOPPING);
		return call RadioState.turnOff();
	} else if(call SplitControlState.isState(S_STOPPED)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.stop() - S_STOPPED");
		return EALREADY;

	} else if(call SplitControlState.isState(S_TRANSMITTING)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.stop() - S_TRANSMITTING");
		call SplitControlState.forceState(S_STOPPING);
		// At sendDone, the radio will shut down
		return SUCCESS;

	} else if(call SplitControlState.isState(S_STOPPING)) {
		dbg("Mac", "csmaMac CSMATransmitP SplitControl.stop() - S_STOPPING");
		return SUCCESS;
	}
	return EBUSY;
}

/***************** Send Commands ****************/
command error_t Send.cancel( message_t* p_msg ) {
	dbg("Mac", "csmaMac CSMATransmitP Send.cancel(0x%1x)", p_msg);
	switch( m_state ) {
	case S_LOAD:
	case S_SAMPLE_CCA:
	case S_BEGIN_TRANSMIT:
		m_state = S_CANCEL;
		break;

	default:
		// cancel not allowed while radio is busy transmitting
		return FAIL;
	}
}

command error_t Send.send( message_t* p_msg, uint8_t len ) {
	csmaca_header_t* header;
	metadata_t* metadata;
	dbg("Mac", "csmaMac CSMATransmitP Send.send(0x%1x, %d)", p_msg, len);

	header = (csmaca_header_t*) call Send.getPayload( p_msg, len);
	metadata = (metadata_t*) p_msg->metadata;

	if ((!call csmacaParams.get_ack()) && (header->fcf & 1 << IEEE154_FCF_ACK_REQ)) {
		header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	}

	atomic {
		if (!call SplitControlState.isState(S_STARTED)) {
			dbg("Mac", "csmaMac CSMATransmitP Send.send() - FAIL - isState(S_STARTED)");
			return FAIL;
		}

		call SplitControlState.forceState(S_TRANSMITTING);
		m_msg = p_msg;
	}

	// header->length = len + CC2420_SIZE;
#ifdef CC2420_HW_SECURITY
	header->fcf &= ((1 << IEEE154_FCF_ACK_REQ)|
                    (1 << IEEE154_FCF_SECURITY_ENABLED)|
                    (0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
                    (0x3 << IEEE154_FCF_DEST_ADDR_MODE));
#else
	header->fcf &= ((1 << IEEE154_FCF_ACK_REQ) |
                    (0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
                    (0x3 << IEEE154_FCF_DEST_ADDR_MODE));
#endif
	header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
                     ( 1 << IEEE154_FCF_INTRAPAN ) );

	metadata->ack = !call csmacaParams.get_ack();
	metadata->rssi = 0;
	metadata->lqi = 0;

	csmaca_backoff_period = call csmacaParams.get_backoff();
	csmaca_min_backoff = call csmacaParams.get_min_backoff();
	csmaca_delay_after_receive = call csmacaParams.get_delay_after_receive();

	if (m_state == S_CANCEL) {
		return ECANCEL;
	}

	if ( m_state != S_STARTED ) {
		dbg("Mac", "csmaMac CSMATransmitP Send.send() - FAIL - m_state != S_STARTED");
		return FAIL;
	}

	m_state = S_LOAD;
	m_cca = call csmacaParams.get_cca();
	m_msg = m_msg;
	totalCcaChecks = 0;

	sendDoneErr = call RadioBuffer.load(m_msg);
	if (sendDoneErr != SUCCESS) {
		dbg("Mac", "csmaMac CSMATransmitP Send.send() - FAIL - RadioBuffer.load(0x%1x)", m_msg);
		post signalSendDone();
		return sendDoneErr;
	}
	return SUCCESS;
}

command void* Send.getPayload(message_t* m, uint8_t len) {
	uint8_t *p = (uint8_t*)(m->data);
	return (p + call RadioPacket.headerLength(m));
}

command uint8_t Send.maxPayloadLength() {
	return call RadioPacket.maxPayloadLength();
}

event void RadioResource.granted() {}

/***************** Tasks ****************/
task void sendDone_task() {
	error_t packetErr;
	atomic packetErr = sendErr;
	if(call SplitControlState.isState(S_STOPPING)) {
		shutdown();
	} else {
		call SplitControlState.forceState(S_STARTED);
	}

	signal Send.sendDone( m_msg, packetErr );
}

task void startDone_task() {
	csmaca_backoff_period = call csmacaParams.get_backoff();
	csmaca_min_backoff = call csmacaParams.get_min_backoff();
	csmaca_delay_after_receive = call csmacaParams.get_delay_after_receive();

	m_state = S_STARTED;

	call SplitControlState.forceState(S_STARTED);
	signal SplitControl.startDone( SUCCESS );
}

task void stopDone_task() {
	call SplitControlState.forceState(S_STOPPED);
	signal SplitControl.stopDone( SUCCESS );
}

/***************** Functions ****************/
/**
 * Shut down all sub-components and turn off the radio
 */
void shutdown() {
	m_state = S_STOPPED;
	call BackoffTimer.stop();
	post stopDone_task();
}


void requestInitialBackoff(message_t *msg, bool resend) {
	if ((csmaca_delay_after_receive > 0) && (resend)) {
		myInitialBackoff = ( call Random.rand16() % (0x4 * csmaca_backoff_period) + csmaca_min_backoff);
	} else {
		myInitialBackoff = ( call Random.rand16() % (0x1F * csmaca_backoff_period) + csmaca_min_backoff);
	}
	dbg("Mac-Detail", "csmaMac CSMATransmitP requestInitialBackoff(0x%1x) myInitialBackoff = %d", msg, myInitialBackoff);
}


void congestionBackoff(message_t *msg) {
//	myCongestionBackoff = ( call Random.rand16() % (0x3 * csmaca_backoff_period) + csmaca_min_backoff);
	myCongestionBackoff = ( call Random.rand16() % (0x7 * csmaca_backoff_period) + csmaca_min_backoff);

	dbg("Mac-Detail", "csmaMac congestionBackoff(0x%1x) is %d", msg, myCongestionBackoff);

	if (myCongestionBackoff) {
		call BackoffTimer.start(myCongestionBackoff);
	} else {
		signal BackoffTimer.fired();
	}
}

/**
 * Resend a packet that already exists in the outbound tx buffer on the
 * chip
 * @param cca TRUE if this transmit should use clear channel assessment
 */
command error_t CSMATransmit.resend(message_t *msg, bool useCca) {
	if (m_msg != msg) {
		return FAIL;
	}

	if (m_state == S_CANCEL) {
		return ECANCEL;
	}

	if ( m_state != S_STARTED ) {
		return FAIL;
	}

	m_cca = useCca;
	m_state = useCca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
	totalCcaChecks = 0;

	if(m_cca) {
		requestInitialBackoff(m_msg, TRUE);
		if (myInitialBackoff) {
			call BackoffTimer.start( myInitialBackoff );
		} else {
			signal BackoffTimer.fired();
		}
	} else {
		if (call RadioSend.send(m_msg, useCca) != SUCCESS) {
			signal RadioSend.sendDone(m_msg, FAIL);
			return FAIL;
		}
	}
	return SUCCESS;
}

async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
	if(call SplitControlState.isState(S_STOPPING)) {
		dbg("Mac", "csmaMac CSMATransmitP RadioBuffer.loadDone(0x%1x, %d) - STOPPING",
						msg, error);
		shutdown();
		return;
	}
	if (error != SUCCESS) {
		dbg("Mac", "csmaMac CSMATransmitP RadioBuffer.loadDone(0x%1x, %d) != SUCCESS"
						, msg, error);
		sendDoneErr = error;
		post signalSendDone();
		return;
	}

	if ( m_state == S_CANCEL ) {
		dbg("Mac", "csmaMac CSMATransmitP RadioBuffer.loadDone(0x%1x, %d) = S_CANCEL",
						msg, error);
		sendDoneErr = ECANCEL;
		post signalSendDone();
	} else if ( !m_cca ) {
		dbg("Mac", "csmaMac CSMATransmitP start sending");
		m_state = S_BEGIN_TRANSMIT;
		if (call RadioSend.send(m_msg, m_cca) != SUCCESS) {
			dbg("Mac", "csmaMac CSMATransmitP RadioSend.send(0x%1x, %d)", m_msg, m_cca);
			signal RadioSend.sendDone(m_msg, FAIL);
		}
	} else {
		m_state = S_SAMPLE_CCA;

		dbg("Mac", "csmaMac CSMATransmitP RadioBuffer.loadDone(0x%1x, %d) = SAMPLE_CCA",
					msg, error);
		requestInitialBackoff(msg, FALSE);
		if (myInitialBackoff) {
			call BackoffTimer.start(myInitialBackoff);
		} else {
			signal BackoffTimer.fired();
		}
	}
}


/***************** Timer Events ****************/
  /**
   * The backoff timer is mainly used to wait for a moment before trying
   * to send a packet again. But we also use it to timeout the wait for
   * an acknowledgement, and timeout the wait for an SFD interrupt when
   * we should have gotten one.
   */
async event void BackoffTimer.fired() {
	dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired()");
	dbg("Mac", "csmaMac CSMATransmitP BackoffTimer.fired()");
	if(call SplitControlState.isState(S_STOPPING)) {
		dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - S_STOPPING");
		shutdown();
		return;
	}

	switch( m_state ) {
        
	case S_SAMPLE_CCA : 
		// sample CCA and wait a little longer if free, just in case we
		// sampled during the ack turn-around window
		if ( call RadioCCA.request() == SUCCESS ) {
			dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - S_SAMPLE_CCA -> S_BEGIN_TRANSMIT");
			m_state = S_BEGIN_TRANSMIT;
			call BackoffTimer.start( TIME_ACK_TURNAROUND );    
		} else {
			dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - S_SAMPLE_CCA");
			congestionBackoff(m_msg);
		}
		break;
        
	case S_BEGIN_TRANSMIT:
		dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - S_BEGIN_TRANSMIT");
		if (call RadioSend.send(m_msg, m_cca) != SUCCESS) {
			dbg("Mac", "csmaMac CSMATransmitP RadioSend.send() != SUCCESS");
			signal RadioSend.sendDone(m_msg, FAIL);
			return;
		}
		dbg("Mac", "csmaMac CSMATransmitP RadioSend.send() == SUCCESS");
		break;

	case S_CANCEL:
		dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - S_CANCEL");
		m_state = S_STARTED;
		sendDoneErr = ECANCEL;
		post signalSendDone();
		break;
        
	default:
		dbg("Mac-Detail", "csmaMac CSMATransmitP BackoffTimer.fired() - default");
		break;
	}
}
      
async event void RadioSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "csmaMac CSMATransmitP RadioSend.sendDone(0x%1x, %d)", msg, error);
	if (m_state == S_CANCEL){
		sendDoneErr = ECANCEL;
		post signalSendDone();
	} else {
		if (error == EBUSY) {
			m_state = S_SAMPLE_CCA;
			totalCcaChecks = 0;
			congestionBackoff(m_msg);
		} else {
			call BackoffTimer.stop();
			sendDoneErr = error;
			post signalSendDone();
		}
	}
}

async event void RadioSend.ready() {
}


async event void RadioCCA.done(error_t err) {

}


event void RadioState.done() {
	if (call SplitControlState.isState(S_STARTING)) {
		dbg("Mac", "csmaMac CSMATransmitP RadioState.done() - post startDone_task");
		post startDone_task();
	}


	if (call SplitControlState.isState(S_STOPPING)) {
		dbg("Mac", "csmaMac CSMATransmitP RadioState.done() - shutdown()");
		shutdown();
	}
}



}

