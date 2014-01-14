/*
 * Copyright (c) 2007, Vanderbilt University
 * Copyright (c) 2011, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 * Author: Andras Biro
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
  * Fennec Fox rf212 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/11/2014
  */


#include <RF212DriverLayer.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>
#include "RFX_IEEE.h"

module RF212DriverLayerP {
provides interface Init as PlatformInit @exactlyonce();
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

uses interface GeneralIO as SELN;
uses interface Resource as SpiResource;
uses interface FastSpiByte;
uses interface GeneralIO as SLP_TR;
uses interface GeneralIO as RSTN;
uses interface GpioCapture as IRQ;
uses interface BusyWait<TMicro, uint16_t>;
uses interface LocalTime<TRadio>;
uses interface RadioAlarm;
uses interface rf212RadioParams;
}

implementation {

rf212_hdr_t* getHeader(message_t* msg) {
	return (rf212_hdr_t*)msg->data;
}

void* getPayload(message_t* msg) {
	return ((void*)msg->data);
}

/*----------------- STATE -----------------*/

norace uint8_t state;
enum {
	STATE_P_ON = 0,
	STATE_SLEEP = 1,
	STATE_SLEEP_2_TRX_OFF = 2,
	STATE_TRX_OFF = 3,
	STATE_TRX_OFF_2_RX_ON = 4,
	STATE_RX_ON = 5,
	STATE_BUSY_TX_2_RX_ON = 6,
};

norace uint8_t cmd;
enum {
	CMD_NONE = 0,			// the state machine has stopped
	CMD_TURNOFF = 1,		// goto SLEEP state
	CMD_STANDBY = 2,		// goto TRX_OFF state
	CMD_TURNON = 3,			// goto RX_ON state
	CMD_TRANSMIT = 4,		// currently transmitting a message
	CMD_RECEIVE = 5,		// currently receiving a message
	CMD_CCA = 6,			// performing clear chanel assesment
	CMD_CHANNEL = 7,		// changing the channel
	CMD_SIGNAL_DONE = 8,		// signal the end of the state transition
	CMD_DOWNLOAD = 9,		// download the received message
};
	
enum {
	// this disables the RF212OffP component
	RF212RADIOON = unique("RF212RadioOn"),
};

norace bool radioIrq;

norace uint8_t txPower;
norace uint8_t channel;

norace message_t* rxMsg;
message_t rxMsgBuffer;

uint16_t capturedTime;	// the current time when the last interrupt has occured
norace uint8_t rssiClear;
norace uint8_t rssiBusy;

void task_run();

/*----------------- REGISTER -----------------*/

inline void writeRegister(uint8_t reg, uint8_t value) {
	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );
	call SELN.clr();
	call FastSpiByte.splitWrite(RF212_CMD_REGISTER_WRITE | reg);
	call FastSpiByte.splitReadWrite(value);
	call FastSpiByte.splitRead();
	call SELN.set();
}

inline uint8_t readRegister(uint8_t reg) {
	RADIO_ASSERT( call SpiResource.isOwner() );
	RADIO_ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );
	call SELN.clr();
	call FastSpiByte.splitWrite(RF212_CMD_REGISTER_READ | reg);
	call FastSpiByte.splitReadWrite(0);
	reg = call FastSpiByte.splitRead();
	call SELN.set();

	return reg;
}

/*----------------- ALARM -----------------*/

// TODO: these constants are depending on the (changable) physical layer
enum {
	TX_SFD_DELAY = (uint16_t)(177 * RADIO_ALARM_MICROSEC),
	RX_SFD_DELAY = (uint16_t)(8 * RADIO_ALARM_MICROSEC),
};

async event void RadioAlarm.fired() {
}

/*----------------- INIT -----------------*/

command error_t PlatformInit.init() {
	call SELN.makeOutput();
	call SELN.set();
	call SLP_TR.makeOutput();
	call SLP_TR.clr();
	call RSTN.makeOutput();
	call RSTN.set();

	rxMsg = &rxMsgBuffer;

	// these are just good approximates
	rssiClear = 0;
	rssiBusy = 90;

	return SUCCESS;
}

command error_t SoftwareInit.init() {
	// for powering up the radio
	return call SpiResource.request();
}

void resetRadio() {
	//TODO: all waiting should be optimized in this function
	call BusyWait.wait(15);
	call RSTN.clr();
	call SLP_TR.clr();
	call BusyWait.wait(15);
	call RSTN.set();
	writeRegister(RF212_TRX_CTRL_0, RF212_TRX_CTRL_0_VALUE);
	writeRegister(RF212_TRX_STATE, RF212_TRX_OFF);

	//this is way too much (should be done in around 200us), but 510 seemd too short, and it happens quite rarely
	call BusyWait.wait(1000);

	writeRegister(RF212_IRQ_MASK, RF212_IRQ_TRX_UR | RF212_IRQ_PLL_LOCK | RF212_IRQ_TRX_END | RF212_IRQ_RX_START | RF212_IRQ_CCA_ED_DONE);
	// update register values if different from default
	if( RF212_CCA_THRES_VALUE != 0x77 )
		writeRegister(RF212_CCA_THRES, RF212_CCA_THRES_VALUE);

	if( RF212_DEF_RFPOWER != 0x60 )
		writeRegister(RF212_PHY_TX_PWR, RF212_DEF_RFPOWER);

	if( RF212_TRX_CTRL_2_VALUE != RF212_DATA_MODE_DEFAULT )
		writeRegister(RF212_TRX_CTRL_2, RF212_TRX_CTRL_2_VALUE);

	writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);
	state = STATE_TRX_OFF;
}

void initRadio() {
	call BusyWait.wait(510);

	call RSTN.clr();
	call SLP_TR.clr();
	call BusyWait.wait(6);
	call RSTN.set();

	writeRegister(RF212_TRX_CTRL_0, RF212_TRX_CTRL_0_VALUE);
	writeRegister(RF212_TRX_STATE, RF212_TRX_OFF);

	call BusyWait.wait(510);
	writeRegister(RF212_IRQ_MASK, RF212_IRQ_TRX_UR | RF212_IRQ_PLL_LOCK | RF212_IRQ_TRX_END | RF212_IRQ_RX_START | RF212_IRQ_CCA_ED_DONE);
	// update register values if different from default
	if( RF212_CCA_THRES_VALUE != 0x77 )
		writeRegister(RF212_CCA_THRES, RF212_CCA_THRES_VALUE);

	if( RF212_DEF_RFPOWER != 0x60 )
		writeRegister(RF212_PHY_TX_PWR, RF212_DEF_RFPOWER);

	if( RF212_TRX_CTRL_2_VALUE != RF212_DATA_MODE_DEFAULT )
		writeRegister(RF212_TRX_CTRL_2, RF212_TRX_CTRL_2_VALUE);

	txPower = RF212_DEF_RFPOWER;
	channel = RF212_DEF_CHANNEL & RF212_CHANNEL_MASK;
	writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

	call SLP_TR.set();
	state = STATE_SLEEP;
}

/*----------------- SPI -----------------*/
event void SpiResource.granted() {
	call SELN.makeOutput();
	call SELN.set();

	if( state == STATE_P_ON ) {
		initRadio();
		call SpiResource.release();
	}
	else
		task_run();
}

bool isSpiAcquired() {
	if( call SpiResource.isOwner() )
		return TRUE;

	if( call SpiResource.immediateRequest() == SUCCESS ) {
		call SELN.makeOutput();
		call SELN.set();

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

	c &= RF212_CHANNEL_MASK;

	if( cmd != CMD_NONE )
		return EBUSY;
	else if( channel == c )
		return EALREADY;

	channel = c;
	cmd = CMD_CHANNEL;
	task_run();
	return SUCCESS;
}

inline void changeChannel() {
	RADIO_ASSERT( cmd == CMD_CHANNEL );
	RADIO_ASSERT( state == STATE_SLEEP || state == STATE_TRX_OFF || state == STATE_RX_ON );

	if( isSpiAcquired() ) {
		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

		if( state == STATE_RX_ON )
			state = STATE_TRX_OFF_2_RX_ON;
		else
			cmd = CMD_SIGNAL_DONE;
	}
}

/*----------------- TURN ON/OFF -----------------*/

inline void changeState() {
	if( (cmd == CMD_STANDBY || cmd == CMD_TURNON) && state == STATE_SLEEP && isSpiAcquired()) {
		RADIO_ASSERT( ! radioIrq );
		call IRQ.captureRisingEdge();
		state = STATE_SLEEP_2_TRX_OFF;
		call SLP_TR.clr();
	} else if( cmd == CMD_TURNON && state == STATE_TRX_OFF && isSpiAcquired() ) {
		// setChannel was ignored in SLEEP because the SPI was not working, so do it here
		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

		writeRegister(RF212_TRX_STATE, RF212_RX_ON);
		state = STATE_TRX_OFF_2_RX_ON;
	} else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY)
			&& state == STATE_RX_ON && isSpiAcquired() ) {
		call IRQ.disable();
		radioIrq = FALSE;
			
		writeRegister(RF212_TRX_STATE, RF212_FORCE_TRX_OFF);
		state = STATE_TRX_OFF;
	}

	if( cmd == CMD_TURNOFF && state == STATE_TRX_OFF ) {
		readRegister(RF212_IRQ_STATUS); // clear the interrupt register
		call SLP_TR.set();
		state = STATE_SLEEP;
		cmd = CMD_SIGNAL_DONE;
	}
	else if( cmd == CMD_STANDBY && state == STATE_TRX_OFF )
		cmd = CMD_SIGNAL_DONE;
}

command error_t RadioState.turnOff() {
	if( cmd != CMD_NONE )
		return EBUSY;
	else if( state == STATE_SLEEP )
		return EALREADY;

	cmd = CMD_TURNOFF;
	task_run();

	return SUCCESS;
}

command error_t RadioState.standby() {
	if( cmd != CMD_NONE )
		return EBUSY;
	else if( state == STATE_TRX_OFF )
		return EALREADY;

	cmd = CMD_STANDBY;
	task_run();

	return SUCCESS;
}

command error_t RadioState.turnOn() {
	if( cmd != CMD_NONE )
		return EBUSY;
	else if( state == STATE_RX_ON )
		return EALREADY;

	cmd = CMD_TURNON;
	task_run();

	return SUCCESS;
}


/*----------------- TRANSMIT -----------------*/

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	uint16_t time;
	uint32_t time32;
	uint8_t* data;
	uint8_t length;
	uint8_t upload1;
	uint8_t upload2;

	if( cmd != CMD_NONE || state != STATE_RX_ON || radioIrq || ! isSpiAcquired() )
		return EBUSY;

	length = call PacketTransmitPower.isSet(msg) ?
		call PacketTransmitPower.get(msg) : RF212_DEF_RFPOWER;

	if( length != txPower ) {
		txPower = length;
		writeRegister(RF212_PHY_TX_PWR, txPower);
	}

	if( (getHeader(msg)->fcf & IEEE154_DATA_FRAME_MASK) == IEEE154_DATA_FRAME_VALUE
		&& (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) > ((rssiClear + rssiBusy) >> 3) ) {
		call SpiResource.release();
		return EBUSY;
	}

	writeRegister(RF212_TRX_STATE, RF212_PLL_ON);

	// do something useful, just to wait a little
	time32 = call LocalTime.get();
	data = getPayload(msg);
	length = getHeader(msg)->length;

	if( call PacketTimeSync.isSet(msg) ) {	
		// TODO - this is wrong
		// the number of bytes before the embedded timestamp
		upload1 = (((void*)msg) + (call RadioPacket.headerLength(msg) +
	                call RadioPacket.payloadLength(msg)) - (void*)data);

		// the FCS is automatically generated (2 bytes)
		upload2 = length - 2 - upload1;

		// make sure that we have enough space for the timestamp
		RADIO_ASSERT( upload2 >= 4 && upload2 <= 127 );
	} else {
		upload1 = length - 2;
		upload2 = 0;
	}
	RADIO_ASSERT( upload1 >= 1 && upload1 <= 127 );

	// we have missed an incoming message in this short amount of time
	if( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) != RF212_PLL_ON ) {
		RADIO_ASSERT( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) == RF212_BUSY_RX );

		writeRegister(RF212_TRX_STATE, RF212_RX_ON);
		call SpiResource.release();
		return EBUSY;
	}

#ifndef RF212_SLOW_SPI
	atomic {
		call SLP_TR.set();
		time = call RadioAlarm.getNow();
	}
	call SLP_TR.clr();
#endif

	RADIO_ASSERT( ! radioIrq );

	call SELN.clr();
	call FastSpiByte.splitWrite(RF212_CMD_FRAME_WRITE);

	// length | data[0] ... data[length-3] | automatically generated FCS
	call FastSpiByte.splitReadWrite(length);

	do {
		call FastSpiByte.splitReadWrite(*(data++));
	}
	while( --upload1 != 0 );

#ifdef RF212_SLOW_SPI
	atomic {
		call SLP_TR.set();
		time = call RadioAlarm.getNow();
	}
	call SLP_TR.clr();
#endif

	time32 += (int16_t)(time + TX_SFD_DELAY) - (int16_t)(time32);

	if( upload2 != 0 ) {
		uint32_t absolute = *(timesync_absolute_t*)data;
		*(timesync_relative_t*)data = absolute - time32;

		// do not modify the data pointer so we can reset the timestamp
		RADIO_ASSERT( upload1 == 0 );
		do {
			call FastSpiByte.splitReadWrite(data[upload1]);
		}
		while( ++upload1 != upload2 );

		*(timesync_absolute_t*)data = absolute;
	}
		
	//dummy bytes for FCS. Otherwise we'll get an TRX_UR interrupt. It's strange though, the RF23x, doesn't need this
	call FastSpiByte.splitReadWrite(0);
	call FastSpiByte.splitReadWrite(0);

	// wait for the SPI transfer to finish
	call FastSpiByte.splitRead();
	call SELN.set();

	/*
	 * There is a very small window (~1 microsecond) when the RF212 went
	 * into PLL_ON state but was somehow not properly initialized because
	 * of an incoming message and could not go into BUSY_TX. I think the
	 * radio can even receive a message, and generate a TRX_UR interrupt
	 * because of concurrent access, but that message probably cannot be
	 * recovered.
	 *
	 * TODO: this needs to be verified, and make sure that the chip is
	 * not locked up in this case.
	 */

	// go back to RX_ON state when finished
	writeRegister(RF212_TRX_STATE, RF212_RX_ON);

	call PacketTimeSync.set(msg, time32);

	// wait for the TRX_END interrupt
	state = STATE_BUSY_TX_2_RX_ON;
	cmd = CMD_TRANSMIT;

	return SUCCESS;
}


/*----------------- CCA -----------------*/

async command error_t RadioCCA.request() {
	if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() )
		return EBUSY;

	cmd = CMD_CCA;
	writeRegister(RF212_PHY_CC_CCA, RF212_CCA_REQUEST | RF212_CCA_MODE_VALUE | channel);

	return SUCCESS;
}

default async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

inline void downloadMessage() {
	uint8_t length;
	bool crcValid = FALSE;

	call SELN.clr();
	call FastSpiByte.write(RF212_CMD_FRAME_READ);

	// read the length byte
	length = call FastSpiByte.write(0);

	// if correct length
	if( length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2 ) {
		uint8_t read;
		uint8_t* data;

		// initiate the reading
		call FastSpiByte.splitWrite(0);

		data = getPayload(rxMsg);
		getHeader(rxMsg)->length = length;

		// we do not store the CRC field
		length -= 2;

		read = 7; // headerPreloadLength
		if( length < read )
			read = length;

		length -= read;

		do {
			*(data++) = call FastSpiByte.splitReadWrite(0);
		}
		while( --read != 0  );

		if( signal RadioReceive.header(rxMsg) ) {
			while( length-- != 0 )
				*(data++) = call FastSpiByte.splitReadWrite(0);

			call FastSpiByte.splitReadWrite(0);	// two CRC bytes
			call FastSpiByte.splitReadWrite(0);

			call PacketLinkQuality.set(rxMsg, call FastSpiByte.splitReadWrite(0));
			call FastSpiByte.splitReadWrite(0);	// ED
			crcValid = call FastSpiByte.splitRead() & RF212_RX_CRC_VALID;	// RX_STATUS
		}
		else
			call FastSpiByte.splitRead(); // finish the SPI transfer
	}

	call SELN.set();
	state = STATE_RX_ON;

	cmd = CMD_NONE;

	// signal only if it has passed the CRC check
	if( crcValid )
		rxMsg = signal RadioReceive.receive(rxMsg);
}

/*----------------- IRQ -----------------*/

async event void IRQ.captured(uint16_t time) {
	RADIO_ASSERT( ! radioIrq );

	atomic {
		capturedTime = time;
		radioIrq = TRUE;
	}

	task_run();
}

void serviceRadio() {
	if( state != STATE_SLEEP && isSpiAcquired() ) {
		uint16_t time;
		uint32_t time32;
		uint8_t irq;
		uint8_t temp;

		atomic time = capturedTime;
		radioIrq = FALSE;
		irq = readRegister(RF212_IRQ_STATUS);
		//this is really bad, but unfortunatly sometimes happens (e.g. radio receives a message while turning on). can't found better solution than reset
		if(irq == 0 ){
			RADIO_ASSERT(FALSE);
			if (cmd == CMD_TURNON){
				resetRadio();
				//CMD_TURNON will be restarted at the tasklet when serviceRadio returns
			} else
				RADIO_ASSERT(FALSE);
			/*
			 * We don't care (yet) with CHANNEL, CCA, RECEIVE and TRANSMIT, mostly becouse all of them needs to turn the radio back on, which needs PLL_LOCK irq,
			 * but we don't want to signal RadioState.done()
			 * However it seems most problems happens when turning on the radio
			 */
			return;
		}

#ifdef RF212_RSSI_ENERGY
		if( irq & RF212_IRQ_TRX_END ) {
			if( irq == RF212_IRQ_TRX_END ||
				(irq == (RF212_IRQ_RX_START | RF212_IRQ_TRX_END) && cmd == CMD_NONE) )
				call PacketRSSI.set(rxMsg, readRegister(RF212_PHY_ED_LEVEL));
			else
				call PacketRSSI.clear(rxMsg);
		}
#endif

		if ( irq & RF212_IRQ_CCA_ED_DONE) {
			if( state == STATE_SLEEP_2_TRX_OFF )
				state = STATE_TRX_OFF;
			else if( cmd == CMD_CCA )
			{
				uint8_t cca;
				RADIO_ASSERT( state == STATE_RX_ON );

				cmd = CMD_NONE;
				cca = readRegister(RF212_TRX_STATUS);

				// sometimes we don't handle yet the RX_START interrupt, but we're already receiving.
				// It's all right though, CCA reports busy as it should.
				RADIO_ASSERT( (cca & RF212_TRX_STATUS_MASK) == RF212_RX_ON || (cca & RF212_TRX_STATUS_MASK) == RF212_BUSY_RX);

				signal RadioCCA.done( (cca & RF212_CCA_DONE) ? ((cca & RF212_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
			}
			else if( state != STATE_RX_ON ) //if we receive a message during CCA, we will still get this interrupt, but we're already reported FAIL at RX_START
				RADIO_ASSERT(FALSE);
		}

//			This should be OK now, since we enable the interrupts in SLEEP state, before changing to TRX_OFF
// 		// sometimes we miss a PLL lock interrupt after turn on
// 		if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
// 		{
// 			RADIO_ASSERT( irq & RF212_IRQ_PLL_LOCK );
// 			RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );
//
// 			state = STATE_RX_ON;
// 			cmd = CMD_SIGNAL_DONE;
// 		}	else
		if( irq & RF212_IRQ_PLL_LOCK )
		{
			RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );
			if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
			{
				state = STATE_RX_ON;
				cmd = CMD_SIGNAL_DONE;
			} else
				RADIO_ASSERT( FALSE );
		}

		if( irq & RF212_IRQ_RX_START )
		{
			if( cmd == CMD_CCA )
			{
				cmd = CMD_NONE;
				signal RadioCCA.done(FAIL);
			}
			if( cmd == CMD_NONE )
			{
				RADIO_ASSERT( state == STATE_RX_ON );
				// the most likely place for busy channel, with no TRX_END interrupt
				if( irq == RF212_IRQ_RX_START )
				{
					temp = readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK;
					rssiBusy += temp - (rssiBusy >> 2);
#ifndef RF212_RSSI_ENERGY
					call PacketRSSI.set(rxMsg, temp);
				}
				else
				{
					call PacketRSSI.clear(rxMsg);
#endif
				}

				/*
				 * The timestamp corresponds to the first event which could not
				 * have been a PLL_LOCK because then cmd != CMD_NONE, so we must
				 * have received a message (and could also have received the
				 * TRX_END interrupt in the mean time, but that is fine. Also,
				 * we could not be after a transmission, because then cmd =
				 * CMD_TRANSMIT.
				 */
				if( irq == RF212_IRQ_RX_START ) // just to be cautious
				{
					time32 = call LocalTime.get();
					time32 += (int16_t)(time - RX_SFD_DELAY) - (int16_t)(time32);
					call PacketTimeSync.set(rxMsg, time32);
				}
				else {
					call PacketTimeSync.clear(rxMsg);
				}
				cmd = CMD_RECEIVE;
			}
			else
				RADIO_ASSERT( cmd == CMD_TURNOFF );
		}

		if( irq & RF212_IRQ_TRX_END )
		{
			if( cmd == CMD_TRANSMIT )
			{
				RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );
				state = STATE_RX_ON;
				cmd = CMD_NONE;
				signal RadioSend.sendDone(rxMsg, SUCCESS);

				// TODO: we could have missed a received message
				RADIO_ASSERT( ! (irq & RF212_IRQ_RX_START) );
			}
			else if( cmd == CMD_RECEIVE )
			{
				RADIO_ASSERT( state == STATE_RX_ON );

				// the most likely place for clear channel (hope to avoid acks)
				rssiClear += (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) - (rssiClear >> 2);
				cmd = CMD_DOWNLOAD;
			}
			else
				RADIO_ASSERT(FALSE);
		}
	}
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
	if( radioIrq )
		serviceRadio();

	if( cmd != CMD_NONE )
	{
		if( cmd == CMD_DOWNLOAD )
			downloadMessage();
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

	if( cmd == CMD_NONE && state == STATE_RX_ON && ! radioIrq )
		signal RadioSend.ready();

	if( cmd == CMD_NONE )
		post releaseSpi();
}

/*----------------- RadioPacket -----------------*/

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	nx_struct rf212_radio_header_t *hdr = (nx_struct rf212_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct rf212_radio_header_t) - RF212_SIZEOF_CRC - sizeof(timesync_radio_t);
}


async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct rf212_radio_header_t *hdr = (nx_struct rf212_radio_header_t*)(msg->data);
	return hdr->length - sizeof(nx_struct rf212_radio_header_t) - RF212_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct rf212_radio_header_t *hdr = (nx_struct rf212_radio_header_t*)(msg->data);
	hdr->length = length + sizeof(nx_struct rf212_radio_header_t) + RF212_SIZEOF_CRC + sizeof(timesync_radio_t);
}


async command uint8_t RadioPacket.maxPayloadLength() {
	return RF212_MAX_MESSAGE_SIZE - sizeof(nx_struct rf212_radio_header_t) - RF212_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
	return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
	memset(msg, 0x0, sizeof(message_t));
}

async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call PacketLinkQuality.get(msg) > 200;
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



}
