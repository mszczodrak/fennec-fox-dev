/*
 * Copyright (c) 2013, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */

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
  * Fennec Fox cc2420x radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/12/2014
  */


#include <CC2420XDriverLayer.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>
#include "CC2420.h"
#include "Ieee154.h"
#include "RFX_IEEE.h"
module CC2420XDriverLayerP {
provides interface Init as SoftwareInit @exactlyonce();

provides interface RadioState;
provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata;

uses interface Resource as SpiResource;
uses interface BusyWait<TMicro, uint16_t>;
uses interface LocalTime<TRadio>;

uses interface FastSpiByte;
uses interface GeneralIO as CSN;
uses interface GeneralIO as VREN;
uses interface GeneralIO as CCA;
uses interface GeneralIO as RSTN;
uses interface GeneralIO as FIFO;
uses interface GeneralIO as FIFOP;
uses interface GeneralIO as SFD;
uses interface GpioCapture as SfdCapture;
uses interface GpioInterrupt as FifopInterrupt;

uses interface RadioAlarm;
uses interface Leds;
uses interface cc2420xParams;
}

implementation {

typedef nx_uint32_t timesync_radio_t;

cc2420x_hdr_t* getHeader(message_t* msg) {
	return (cc2420x_hdr_t*)msg->data;
}

void* getPayload(message_t* msg) {
	return ((void*)msg->data);
}

/*----------------- STATE -----------------*/

enum {
	STATE_VR_ON = 0,
	STATE_PD = 1,
	STATE_PD_2_IDLE = 2,
	STATE_IDLE = 3,
	STATE_IDLE_2_RX_ON = 4,
	STATE_RX_ON = 5,
	STATE_BUSY_TX_2_RX_ON = 6,
	STATE_IDLE_2_TX_ON = 7,
	STATE_TX_ON = 8,
	STATE_RX_DOWNLOAD = 9,
};
norace uint8_t state = STATE_VR_ON;

enum {
	CMD_NONE = 0,			// the state machine has stopped
	CMD_TURNOFF = 1,		// goto SLEEP state
	CMD_STANDBY = 2,		// goto TRX_OFF state
	CMD_TURNON = 3,			// goto RX_ON state
	CMD_TRANSMIT = 4,		// currently transmitting a message
	CMD_RECEIVE = 5,		// currently receiving a message
	CMD_CCA = 6,			// performing clear chanel assesment
	CMD_CHANNEL = 7,		// changing the channel
	CMD_SIGNAL_DONE = 8,	// signal the end of the state transition
	CMD_DOWNLOAD = 9,		// download the received message
};
norace uint8_t cmd = CMD_NONE;

// flag: RX SFD was captured, but not yet processed
norace bool rxSfd = 0;
// flag: end of TX event (falling SFD edge) was captured, but not yet processed	
norace bool txEnd = 0;

norace uint8_t txPower;
norace uint8_t channel;

norace message_t* rxMsg;
norace message_t* txMsg;
message_t rxMsgBuffer;

norace uint16_t capturedTime;	// time when the last SFD rising edge was captured

inline cc2420X_status_t getStatus();
inline cc2420X_status_t enableReceiveSfd();

void task_run();

/*----------------- ALARM -----------------*/
async event void RadioAlarm.fired() {		
	if( state == STATE_PD_2_IDLE ) {
		state = STATE_IDLE;
		if( cmd == CMD_STANDBY )
			cmd = CMD_SIGNAL_DONE;
	}
	else if( state == STATE_IDLE_2_RX_ON ) {
		state = STATE_RX_ON;
		cmd = CMD_SIGNAL_DONE;
		// in receive mode, enable SFD capture
		RADIO_ASSERT(call SFD.get() == 0);	
	enableReceiveSfd();
	}
	else
		RADIO_ASSERT(FALSE);
	// make sure the rest of the command processing is called
	task_run();
}

/*----------------- REGISTER -----------------*/

inline uint16_t readRegister(uint8_t reg) {		
	uint16_t value = 0;
		
	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

	call CSN.set();
	call CSN.clr();
		
	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_READ | reg);
	call FastSpiByte.splitReadWrite(0);
	value = ((uint16_t)call FastSpiByte.splitReadWrite(0) << 8);
	value += call FastSpiByte.splitRead();
	call CSN.set();

	return value;
}

inline cc2420X_status_t strobe(uint8_t reg) {
	cc2420X_status_t status;
		
	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

	call CSN.set();
	call CSN.clr();

	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | reg);
	status.value = call FastSpiByte.splitRead();

	call CSN.set();
	return status;
		
}

inline cc2420X_status_t getStatus() {
	return strobe(CC2420X_SNOP);
}

inline cc2420X_status_t writeRegister(uint8_t reg, uint16_t value) {
	cc2420X_status_t status;
		
	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

	call CSN.set();
	call CSN.clr();

	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | reg);
	call FastSpiByte.splitReadWrite(value >> 8);
	call FastSpiByte.splitReadWrite(value & 0xff);
	status.value = call FastSpiByte.splitRead();

	call CSN.set();
	return status;		
}

inline cc2420X_status_t writeTxFifo(uint8_t* data, uint8_t length) {
	cc2420X_status_t status;
	uint8_t idx;
		
	RADIO_ASSERT( call SpiResource.isOwner() );

	call CSN.set();
	call CSN.clr();

	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | CC2420X_TXFIFO);
	for(idx = 0; idx<length; idx++)
		call FastSpiByte.splitReadWrite(data[idx]);
	status.value = call FastSpiByte.splitRead();

	call CSN.set();
	return status;		
}

inline uint8_t waitForRxFifo() {

	if(call FIFO.get() == 1) {
		// return quickly if FIFO pin is already high
		return 1;
	} else {

		// wait for fifo to go high or timeout
		// timeout is now + 2 byte time (4 symbol time)
		uint16_t timeout = call RadioAlarm.getNow() + 4 * CC2420X_SYMBOL_TIME;
			
		while(call FIFO.get() == 0 && (timeout - call RadioAlarm.getNow() < 0x7fff));
		return call FIFO.get();
	}
}

inline cc2420X_status_t readLengthFromRxFifo(uint8_t* lengthPtr) {
	cc2420X_status_t status;

	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( call CSN.get() == 1 );

	call CSN.set();	// set CSN, just in clase it's not set
	call CSN.clr(); // clear CSN, starting a multi-byte SPI command

	// wait for fifo to go high
	waitForRxFifo();
	RADIO_ASSERT(call FIFO.get() == 1);

	// issue SPI command
	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_READ | CC2420X_RXFIFO);
	status.value = call FastSpiByte.splitRead();
	call FastSpiByte.splitWrite(0);

	RADIO_ASSERT(status.lock == 1);
	RADIO_ASSERT(status.tx_active == 0);
	RADIO_ASSERT(status.tx_underflow == 0);
	RADIO_ASSERT(status.xosc16m_stable == 1);	
	RADIO_ASSERT(status.lock == 1);	
	RADIO_ASSERT(status.rssi_valid == 1);	
		
	*lengthPtr = call FastSpiByte.splitRead();
		
	// start reading the next byte
	// important! fifo pin must be checked after the previous SPI read completed
	waitForRxFifo();
	call FastSpiByte.splitWrite(0);

	return status;		
}

inline void readPayloadFromRxFifo(uint8_t* data, uint8_t length) {
	uint8_t idx;
		
	// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
	RADIO_ASSERT( call CSN.get() == 0 );

	for(idx = 0; idx<length; idx++) {
		data[idx] = call FastSpiByte.splitRead();
		waitForRxFifo();
		call FastSpiByte.splitWrite(0);
	}
}
	
inline void readRssiFromRxFifo(uint8_t* rssiPtr) {
	// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
	RADIO_ASSERT( call CSN.get() == 0 );

	*rssiPtr = call FastSpiByte.splitRead();
	waitForRxFifo();
	call FastSpiByte.splitWrite(0);
}
	
inline void readCrcOkAndLqiFromRxFifo(uint8_t* crcOkAndLqiPtr) {
	// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
	RADIO_ASSERT( call CSN.get() == 0 );
		
	*crcOkAndLqiPtr = call FastSpiByte.splitRead();	
	
	// end RxFifo read operation
	call CSN.set();
}

inline cc2420X_status_t flushRxFifo() {
	// make sure that at least one byte has been read 
	// from the rx fifo before issuing the flush strobe (datasheet p. 60)
	call CSN.set();	// set CSN, just in clase it's not set
	call CSN.clr(); // clear CSN, starting a multi-byte SPI command	
	call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_READ | CC2420X_RXFIFO);
	call FastSpiByte.splitRead();
	call FastSpiByte.splitWrite(0);
	call FastSpiByte.splitRead(); // read a dummy byte from the rx fifo
	call CSN.set();

	// issue the strobe twice (datasheet p. 32)
	strobe(CC2420X_SFLUSHRX);
	return strobe(CC2420X_SFLUSHRX);
}
	
/*----------------- INIT -----------------*/

command error_t SoftwareInit.init() {
	// set pin directions
    	call CSN.makeOutput();
    	call VREN.makeOutput(); 		
    	call RSTN.makeOutput(); 		
    	call CCA.makeInput();
    	call SFD.makeInput();
    	call FIFO.makeInput();
    	call FIFOP.makeInput();    		

	call FifopInterrupt.disable();
	call SfdCapture.disable();

	// CSN is active low		
    	call CSN.set();

	// start up voltage regulator
    	call VREN.set();
    	call BusyWait.wait( 600 ); // .6ms VR startup time
	txPower = call cc2420xParams.get_power();
	channel = call cc2420xParams.get_channel();
    		
    	// do a reset
	call RSTN.clr();
	call RSTN.set();
    
	rxMsg = &rxMsgBuffer;

	state = STATE_VR_ON;

	// request SPI, rest of the initialization will be done from
	// the granted event
	return call SpiResource.request();
}

inline void resetRadio() {
	cc2420X_iocfg0_t iocfg0;
	cc2420X_mdmctrl0_t mdmctrl0;

    	// do a reset
	call RSTN.clr();
	call RSTN.set();

	// set up fifop polarity and threshold
	iocfg0 = cc2420X_iocfg0_default;
	iocfg0.f.fifop_thr = 127;
      	writeRegister(CC2420X_IOCFG0, iocfg0.value);
		      
	// set up modem control
	mdmctrl0 = cc2420X_mdmctrl0_default;
	mdmctrl0.f.reserved_frame_mode = 1; //accept reserved frames
	mdmctrl0.f.adr_decode = 0; // disable
      	writeRegister(CC2420X_MDMCTRL0, mdmctrl0.value);		

	state = STATE_PD;
}


void initRadio() {
	resetRadio();		
}

/*----------------- SPI -----------------*/

event void SpiResource.granted() {
	call CSN.makeOutput();
	call CSN.set();

	if( state == STATE_VR_ON ) {
		initRadio();
		call SpiResource.release();
	} else
		task_run();
}

bool isSpiAcquired() {
	if( call SpiResource.isOwner() )
		return TRUE;

	if( call SpiResource.immediateRequest() == SUCCESS ) {
		call CSN.makeOutput();
		call CSN.set();

		return TRUE;
	}

	call SpiResource.request();
	return FALSE;
}

/*----------------- CHANNEL -----------------*/

command uint8_t RadioState.getChannel() {
	return channel;
}

command error_t RadioState.setChannel(uint8_t c) {
	c &= CC2420X_CHANNEL_MASK;

	if( cmd != CMD_NONE )
		return EBUSY;
	else if( channel == c )
		return EALREADY;

	channel = c;
	cmd = CMD_CHANNEL;
	task_run();

	return SUCCESS;
}

inline void setChannel() {
	cc2420X_fsctrl_t fsctrl;
	// set up freq
	fsctrl= cc2420X_fsctrl_default;
	fsctrl.f.freq = 357+5*(channel - 11);
	
	writeRegister(CC2420X_FSCTRL, fsctrl.value);
}

inline void changeChannel() {
	RADIO_ASSERT( cmd == CMD_CHANNEL );
	RADIO_ASSERT( state == STATE_PD || state == STATE_IDLE || ( state == STATE_RX_ON && call RadioAlarm.isFree()));

	if( isSpiAcquired() ) {
		setChannel();

		if( state == STATE_RX_ON ) {
			call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods
			state = STATE_IDLE_2_RX_ON;				
		}
		else
			cmd = CMD_SIGNAL_DONE;
	}
}

/*----------------- TURN ON/OFF -----------------*/

inline void changeState() {
	if( (cmd == CMD_STANDBY || cmd == CMD_TURNON)
		&& state == STATE_PD  && isSpiAcquired() && call RadioAlarm.isFree() ) {
		// start oscillator
		strobe(CC2420X_SXOSCON); 

		call RadioAlarm.wait(PD_2_IDLE_TIME); // .86ms OSC startup time
		state = STATE_PD_2_IDLE;
	} else if( cmd == CMD_TURNON && state == STATE_IDLE && isSpiAcquired() && call RadioAlarm.isFree()) {
		// setChannel was ignored in SLEEP because the SPI was not working, so do it here
		setChannel();

		// start receiving
      		strobe(CC2420X_SRXON); 
		call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods      			
		state = STATE_IDLE_2_RX_ON;
	} else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() ) {
		// disable SFD capture
      		call SfdCapture.disable();	

		// stop receiving
     		strobe(CC2420X_SRFOFF); 			
		state = STATE_IDLE;
	}

	if( cmd == CMD_TURNOFF && state == STATE_IDLE  && isSpiAcquired() ) {
      		// stop oscillator
      		strobe(CC2420X_SXOSCOFF); 

		// do a reset
		initRadio();
		state = STATE_PD;
		cmd = CMD_SIGNAL_DONE;
	} else if( cmd == CMD_STANDBY && state == STATE_IDLE )
		cmd = CMD_SIGNAL_DONE;
}

command error_t RadioState.turnOff() {
	if( cmd != CMD_NONE )
		return EBUSY;
	else if( state == STATE_PD )
		return EALREADY;

	cmd = CMD_TURNOFF;
	task_run();

	return SUCCESS;
}
	
command error_t RadioState.standby() {	
	if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
		return EBUSY;
	else if( state == STATE_IDLE )
		return EALREADY;

	cmd = CMD_STANDBY;
	task_run();
	return SUCCESS;
}


command error_t RadioState.turnOn() {
	if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
		return EBUSY;
	else if( state == STATE_RX_ON )
		return EALREADY;

	cmd = CMD_TURNON;
	task_run();

	return SUCCESS;
}

default event void RadioState.done() { }

/*----------------- TRANSMIT -----------------*/

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	uint16_t time;
	uint8_t p;
	uint8_t length;
	uint8_t header;
	uint32_t time32;
	uint32_t sfdTime;
	txMsg = msg;
	if( cmd != CMD_NONE || (state != STATE_IDLE && state != STATE_RX_ON) || ! isSpiAcquired() || rxSfd || txEnd )
		return EBUSY;

	p = (call PacketTransmitPower.isSet(msg) ?
		call PacketTransmitPower.get(msg) : txPower);

	if( p != txPower ) {
		cc2420X_txctrl_t txctrl = cc2420X_txctrl_default;
		txPower = p;
		txctrl.f.pa_level = txPower;
		writeRegister(CC2420X_TXCTRL, txctrl.value);
	}

	if( ((getHeader(msg)->fcf & IEEE154_DATA_FRAME_MASK) == IEEE154_DATA_FRAME_VALUE) 
		&& !call CCA.get() ) {
		return EBUSY;
	}

	length = getHeader(msg)->length;

	// length | data[0] ... data[length-3] | automatically generated FCS
	header = 7; // headerPreloadLength
	if( header > length )
		header = length;

	length -= header;

	// first upload the header to gain some time
	writeTxFifo((void*)msg->data, header);

	atomic {
  		// there's a chance that there was a receive SFD interrupt in such a short time
        	// clean up the TXFIFO and bail out
	        if( cmd != CMD_NONE || (state != STATE_IDLE && state != STATE_RX_ON) || rxSfd || call SFD.get() == 1 ) {
		        // discard header we wrote to TXFIFO
		        strobe(CC2420X_SFLUSHTX);
		        // and bail out
		        return EBUSY;
	        }
		// start transmission
		strobe(CC2420X_STXON);
		// get a timestamp right after strobe returns
		time = call RadioAlarm.getNow();

		cmd = CMD_TRANSMIT;			
		state = STATE_TX_ON;
		call SfdCapture.captureFallingEdge();
	}

	//RADIO_ASSERT(sfd1 == 0);
	RADIO_ASSERT(sfd2 == 0);
	RADIO_ASSERT(sfd3 == 0);
	RADIO_ASSERT(sfd4 == 0);


	if( call PacketTimeSync.isSet(msg)) {
		// timesync required: write the payload before the timesync bytes to the fifo
		// TODO: we're assuming here that the timestamp is at the end of the message
		writeTxFifo((void*)(msg->data)+header, length - sizeof(timesync_absolute_t) - 1);
	} else {
		// no timesync: write the entire payload to the fifo
		if(length>0)
			writeTxFifo((void*)((msg->data)+header), length - 1);
		state = STATE_BUSY_TX_2_RX_ON;
	}
		
		
	// compute timesync
	sfdTime = time;
		
	// read both clocks
	atomic {
		time = call RadioAlarm.getNow();
		time32 = call LocalTime.get();
	}
			
	// adjust time32 with the time elapsed since the SFD event
	time -= sfdTime;
	time32 -= time;

	// adjust for delay between the STXON strobe and the transmission of the SFD
	time32 += TX_SFD_DELAY;

	if( call PacketTimeSync.isSet(msg)) {
		// read and adjust the timestamp field
		uint32_t *relative_time = (uint32_t*)((msg->data) + (call RadioPacket.headerLength(msg) +
									call RadioPacket.payloadLength(msg)));
		*relative_time -= time32;
		// write it to the fifo
		// TODO: we're assuming here that the timestamp is at the end of the message			
		writeTxFifo((uint8_t*)(&relative_time), sizeof(timesync_absolute_t));
		state = STATE_BUSY_TX_2_RX_ON;
	}

	// SFD capture interrupt will be triggered: we'll reenable interrupts from there
	// and clear the rx fifo -- should something have arrived in the meantime
	return SUCCESS;
}

/*----------------- CCA -----------------*/

async command error_t RadioCCA.request() {
	if( cmd != CMD_NONE || state != STATE_RX_ON )
		return EBUSY;

	if(call CCA.get()) {
		signal RadioCCA.done(SUCCESS);		
	} else {
		// TODO: remove this
		RADIO_ASSERT(FAIL);
		signal RadioCCA.done(EBUSY);		
	}
	return SUCCESS;
}

default async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

inline cc2420X_status_t enableReceiveSfd() {
	cc2420X_status_t status;
	atomic {
		// turn off the radio first
		strobe(CC2420_SRFOFF);
		// flush rx fifo		
		flushRxFifo();
		// ready to receive new message: enable receive SFD capture
		call SfdCapture.captureRisingEdge();
		// turn the radio back on
		status = strobe(CC2420_SRXON);
	}
	RADIO_ASSERT(sfd1 == 0);			
	RADIO_ASSERT(sfd2 == 0);			
	RADIO_ASSERT(sfd3 == 0);			
	RADIO_ASSERT(fifo == 0);	
	RADIO_ASSERT(fifop == 0);	
	//RADIO_ASSERT(status.lock == 1);
	RADIO_ASSERT(status.tx_active == 0);
	//RADIO_ASSERT(status.tx_underflow == 0);
	RADIO_ASSERT(status.xosc16m_stable == 1);	
	return status;
}


inline void downloadMessage() {
	uint8_t length;
	uint16_t crc = 1;
	uint8_t rssi;
	uint8_t* data;
	uint8_t crc_ok_lqi;
	uint16_t sfdTime;				
						
	state = STATE_RX_DOWNLOAD;
		
	sfdTime = capturedTime;
		
	// data starts after the length field
	data = getPayload(rxMsg) + sizeof(cc2420x_header_t);

	// read the length byte
	readLengthFromRxFifo(&length);

	if (length < 3 || length > call RadioPacket.maxPayloadLength() + 2 ) {
		// bad length: bail out
		state = STATE_RX_ON;
		cmd = CMD_NONE;
		enableReceiveSfd();
			return;	
	}
	
	// if we're here, length must be correct
	RADIO_ASSERT(length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2);

	getHeader(rxMsg)->length = length;

	// we'll read the FCS/CRC separately
	length -= 2;		

	// download the whole payload
	readPayloadFromRxFifo(data, length );

	// the last two bytes are not the fsc, but RSSI(8), CRC_ON(1)+LQI(7)
	readRssiFromRxFifo(&rssi);
	readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);

	/* UNCOMMENT THIS CODE IF THERE ARE TIMESTAMPING ERRORS	
	// there are still bytes in the fifo or if there's an overflow, flush rx fifo
	if (call FIFOP.get() == 1 || call FIFO.get() == 1 || call SFD.get() == 1) {
		RADIO_ASSERT(FALSE);
		state = STATE_RX_ON;
		cmd = CMD_NONE;

		RADIO_ASSERT(call SFD.get() == 0);	
		enableReceiveSfd();
		return;
	}
	*/

	state = STATE_RX_ON;
	cmd = CMD_NONE;

	// ready to receive new message: enable SFD interrupts
	enableReceiveSfd();
		
	// bail out if we're not interested in this message
	if( !signal RadioReceive.header(rxMsg) ) {
		return;
	}

	// set RSSI, CRC and LQI only if we're accepting the message
	call PacketRSSI.set(rxMsg, rssi);
	call PacketLinkQuality.set(rxMsg, crc_ok_lqi & 0x7f);
	crc = (crc_ok_lqi > 0x7f) ? 0 : 1;

	//getMetadata(rxMsg)->rssi = rssi;
	getMetadata(rxMsg)->crc = !crc;

	// signal reception only if it has passed the CRC check
	if( crc == 0 ) {
		uint32_t time32;
		uint16_t time;
		atomic {
			time = call RadioAlarm.getNow();
			time32 = call LocalTime.get();
		}
			
		time -= sfdTime;
		time32 -= time;

		rxMsg = signal RadioReceive.receive(rxMsg);
	}
}


/*----------------- IRQ -----------------*/
	
// RX SFD (rising edge) or end of TX (falling edge)
async event void SfdCapture.captured( uint16_t time ) {
	RADIO_ASSERT( ! rxSfd ); // assert that there's no nesting
	RADIO_ASSERT( ! txEnd ); // assert that there's no nesting

	call SfdCapture.disable();

	if(state == STATE_RX_ON) {
		rxSfd = TRUE;
		capturedTime = time;
	} else if(state == STATE_TX_ON || state == STATE_BUSY_TX_2_RX_ON) {
		txEnd = TRUE;
	} else {
		// received capture interrupt in an invalid state
		RADIO_ASSERT(FALSE); 
	}

	// do the rest of the processing
	task_run();
}

// FIFOP interrupt, last byte received
async event void FifopInterrupt.fired() {		
	// not used
}


default async event bool RadioReceive.header(message_t* msg) {
	return TRUE;
}

default async event message_t* RadioReceive.receive(message_t* msg) {
	return msg;
}

/*----------------- TASKLET -----------------*/

task void releaseSpi() {
	call SpiResource.release();
}

task void radioStateDone() {
	signal RadioState.done();
}

void task_run() {
	if( txEnd ) {
		// end of transmission
		if( isSpiAcquired() )
		{
			cc2420X_status_t status;
			txEnd = FALSE;

			RADIO_ASSERT(state == STATE_TX_ON || state == STATE_BUSY_TX_2_RX_ON);
			RADIO_ASSERT(cmd == CMD_TRANSMIT);

			state = STATE_RX_ON;
			cmd = CMD_NONE;

			// a packet might have been received since the end of the transmission
			status = enableReceiveSfd();

			// check for tx underflow
			if ( status.tx_underflow == 1) {
				RADIO_ASSERT(FALSE);
				// flush tx fifo
				strobe(CC2420X_SFLUSHTX);
				signal RadioSend.sendDone(txMsg, FAIL);
			} else {
				signal RadioSend.sendDone(txMsg, SUCCESS);
			}						
		}
		else
			RADIO_ASSERT(FALSE);
	}

	if( rxSfd ) {
		// incoming packet
		if( isSpiAcquired() )
		{
			rxSfd = FALSE;
			RADIO_ASSERT(state == STATE_RX_ON);
			RADIO_ASSERT(cmd == CMD_NONE);

			cmd = CMD_DOWNLOAD;				
		}
		else
			RADIO_ASSERT(FALSE);
	}

		
	if( cmd != CMD_NONE )
	{
		if( cmd == CMD_DOWNLOAD ) {
			RADIO_ASSERT(state == STATE_RX_ON);
			downloadMessage();
		}
		else if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
			changeState();
		else if( cmd == CMD_CHANNEL )
			changeChannel();
			
		if( cmd == CMD_SIGNAL_DONE )
		{
			cmd = CMD_NONE;
			post radioStateDone();
		}
	}

	if( cmd == CMD_NONE && state == STATE_RX_ON && ! rxSfd && ! txEnd )
		signal RadioSend.ready();

	if( cmd == CMD_NONE )
		post releaseSpi();
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	return sizeof(nx_struct cc2420x_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct cc2420x_radio_header_t *hdr = (nx_struct cc2420x_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct cc2420x_radio_header_t) - CC2420X_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct cc2420x_radio_header_t *hdr = (nx_struct cc2420x_radio_header_t*)(msg->data);
	hdr->length = length + sizeof(nx_struct cc2420x_radio_header_t) + CC2420X_SIZEOF_CRC + sizeof(timesync_radio_t);
}
	

async command uint8_t RadioPacket.maxPayloadLength() {
	return CC2420X_MAX_MESSAGE_SIZE - sizeof(nx_struct cc2420x_radio_header_t) - CC2420X_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
	return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
	memset(msg, 0x0, sizeof(message_t));
}

async command bool PacketTransmitPower.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<1);
}

async command uint8_t PacketTransmitPower.get(message_t* msg) {
	return getMetadata(msg)->tx_power;
}

async command void PacketTransmitPower.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<1);
}

async command void PacketTransmitPower.set(message_t* msg, uint8_t value) {
	getMetadata(msg)->flags |= (1<<1);
	getMetadata(msg)->tx_power = value;
}

async command bool PacketRSSI.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<2);
}

async command uint8_t PacketRSSI.get(message_t* msg) {
	return getMetadata(msg)->rssi;
}

async command void PacketRSSI.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<2);
}

async command void PacketRSSI.set(message_t* msg, uint8_t value) {
	call PacketTransmitPower.clear(msg);
	getMetadata(msg)->flags |= (1<<2);
	getMetadata(msg)->rssi = value;
}

async command bool PacketTimeSync.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<3);
}

async command uint32_t PacketTimeSync.get(message_t* msg) {
	return (uint32_t)(*((msg->data) + (call RadioPacket.headerLength(msg) +
		call RadioPacket.payloadLength(msg))));
}

async command void PacketTimeSync.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<3);
}

async command void PacketTimeSync.set(message_t* msg, uint32_t value) {
	getMetadata(msg)->flags |= (1<<3);
	// we do not store the value, the time sync field is always the last 4 bytes
}

async command bool PacketLinkQuality.isSet(message_t* msg) {
	return TRUE;
}

async command uint8_t PacketLinkQuality.get(message_t* msg) {
	return getMetadata(msg)->lqi;
}

async command void PacketLinkQuality.clear(message_t* msg){
}

async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
	getMetadata(msg)->lqi = value;
}

async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call PacketLinkQuality.get(msg) > 105;
}

}
