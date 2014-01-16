/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Urs Hunkeler (ReadRssi implementation)
 * @version $Revision: 1.7 $ $Date: 2008/06/24 04:07:28 $
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
  * cc2420 driver adapted from the TinyOS ActiveMessage stack for CC2420 and cc2420x
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include "Timer.h"

module cc2420ControlP @safe() {

provides interface Init;
provides interface Resource as RadioResource;
provides interface RadioConfig;
provides interface RadioPower;

uses interface LocalIeeeEui64;

uses interface Alarm<T32khz,uint32_t> as StartupTimer;
uses interface GeneralIO as CSN;
uses interface GeneralIO as RSTN;
uses interface GeneralIO as VREN;
uses interface GpioInterrupt as InterruptCCA;
uses interface ActiveMessageAddress;

uses interface CC2420Ram as IEEEADR;
uses interface CC2420Ram as PANID;
uses interface CC2420Register as FSCTRL;
uses interface CC2420Register as IOCFG0;
uses interface CC2420Register as IOCFG1;
uses interface CC2420Register as MDMCTRL0;
uses interface CC2420Register as MDMCTRL1;
uses interface CC2420Register as RXCTRL1;
uses interface CC2420Register as RSSI;
uses interface CC2420Register as TXCTRL;
uses interface CC2420Strobe as SRXON;
uses interface CC2420Strobe as SRFOFF;
uses interface CC2420Strobe as SXOSCOFF;
uses interface CC2420Strobe as SXOSCON;
  
uses interface Resource as SpiResource;
uses interface Resource as SyncResource;

uses interface Leds;
uses interface cc2420Params;
}

implementation {

uint32_t on_time;

typedef enum {
	S_VREG_STOPPED,
	S_VREG_STARTING,
	S_VREG_STARTED,
	S_XOSC_STARTING,
	S_XOSC_STARTED,
} cc2420_control_state_t;

uint8_t m_channel;
uint8_t m_tx_power;
uint16_t m_pan;
uint16_t m_short_addr;
ieee_eui64_t m_ext_addr;
bool m_sync_busy;
/** TRUE if acknowledgments are enabled */
bool autoAckEnabled;
/** TRUE if acknowledgments are generated in hardware only */
bool hwAutoAckDefault;
/** TRUE if software or hardware address recognition is enabled */
bool addressRecognition;
/** TRUE if address recognition should also be performed in hardware */
bool hwAddressRecognition;
bool autoCrc;
norace cc2420_control_state_t m_state = S_VREG_STOPPED;
  
/***************** Prototypes ****************/
void writeFsctrl();
void writeMdmctrl0();
void writeId();
void writeTxctrl();

task void sync();
task void syncDone();

task void get_params() {
	atomic {
		m_tx_power = call cc2420Params.get_power();
		m_channel = call cc2420Params.get_channel();
		autoAckEnabled = call cc2420Params.get_ack();    
		autoCrc = call cc2420Params.get_crc();
	}
}
    
/***************** Init Commands ****************/
command error_t Init.init() {
	int i, t;
	call CSN.makeOutput();
	call RSTN.makeOutput();
	call VREN.makeOutput();

	on_time = 0;
    
	m_short_addr = call ActiveMessageAddress.amAddress();
	m_ext_addr = call LocalIeeeEui64.getId();
	m_pan = call ActiveMessageAddress.amGroup();
    
	m_ext_addr = call LocalIeeeEui64.getId();
	for (i = 0; i < 4; i++) {
		t = m_ext_addr.data[i];
		m_ext_addr.data[i] = m_ext_addr.data[7-i];
		m_ext_addr.data[7-i] = t;
	}

	m_tx_power = call cc2420Params.get_power();
	m_channel = call cc2420Params.get_channel();

#if defined(CC2420_NO_ADDRESS_RECOGNITION)
	addressRecognition = FALSE;
#else
	addressRecognition = TRUE;
#endif
    
#if defined(CC2420_HW_ADDRESS_RECOGNITION)
	hwAddressRecognition = TRUE;
#else
	hwAddressRecognition = FALSE;
#endif
    
    
#if defined(CC2420_NO_ACKNOWLEDGEMENTS)
	autoAckEnabled = FALSE;
#else
	autoAckEnabled = TRUE;
#endif
    
#if defined(CC2420_HW_ACKNOWLEDGEMENTS)
	hwAutoAckDefault = TRUE;
	hwAddressRecognition = TRUE;
#else
	hwAutoAckDefault = FALSE;
#endif
	return SUCCESS;
}

/***************** Resource Commands ****************/
async command error_t RadioResource.immediateRequest() {
	error_t error = call SpiResource.immediateRequest();
	if ( error == SUCCESS ) {
		call CSN.clr();
	}
	return error;
}

async command error_t RadioResource.request() {
	return call SpiResource.request();
}

async command bool RadioResource.isOwner() {
	return call SpiResource.isOwner();
}

async command error_t RadioResource.release() {
	atomic {
		call CSN.set();
		return call SpiResource.release();
	}
}

task void report_start() {
	on_time = call StartupTimer.getNow();
	//dbgs(F_RADIO, S_NONE, DBGS_RADIO_START_V_REG, (uint16_t)(on_time >> 16), (uint16_t)on_time);
	//dbgs(F_RADIO, S_NONE, DBGS_RADIO_START_V_REG, 0, 0);
}

task void report_stop() {
	//on_time = (call StartupTimer.getNow() - on_time);
	on_time = call StartupTimer.getNow();
	//dbgs(F_RADIO, S_NONE, DBGS_RADIO_STOP_V_REG, (uint16_t)(on_time >> 16), (uint16_t)on_time);
	//dbgs(F_RADIO, S_NONE, DBGS_RADIO_STOP_V_REG, 0, 0);
	//dbgs(F_RADIO, S_NONE, DBGS_RADIO_ON_PERIOD, (uint16_t)(on_time >> 16), (uint16_t)on_time);
}

/***************** RadioPower Commands ****************/
async command error_t RadioPower.startVReg() {
	post get_params();
	atomic {
		if ( m_state != S_VREG_STOPPED ) {
			return FAIL;
		}
		m_state = S_VREG_STARTING;
	}
	call VREN.set();
	call StartupTimer.start( CC2420_TIME_VREN );
	post report_start();
	return SUCCESS;
}

async command error_t RadioPower.stopVReg() {
	m_state = S_VREG_STOPPED;
	call RSTN.clr();
	call VREN.clr();
	call RSTN.set();
	post report_stop();
	return SUCCESS;
}

async command error_t RadioPower.startOscillator() {
	atomic {
		if ( m_state != S_VREG_STARTED ) {
			return FAIL;
		}
        
		m_state = S_XOSC_STARTING;
		call IOCFG1.write( CC2420_SFDMUX_XOSC16M_STABLE << 
			CC2420_IOCFG1_CCAMUX );
                         
		call InterruptCCA.enableRisingEdge();
		call SXOSCON.strobe();
      
		call IOCFG0.write( ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
			( 127 << CC2420_IOCFG0_FIFOP_THR ) );
                         
		writeFsctrl();
		writeMdmctrl0();
  
		call RXCTRL1.write( ( 1 << CC2420_RXCTRL1_RXBPF_LOCUR ) |
			( 1 << CC2420_RXCTRL1_LOW_LOWGAIN ) |
			( 1 << CC2420_RXCTRL1_HIGH_HGM ) |
			( 1 << CC2420_RXCTRL1_LNA_CAP_ARRAY ) |
			( 1 << CC2420_RXCTRL1_RXMIX_TAIL ) |
			( 1 << CC2420_RXCTRL1_RXMIX_VCM ) |
			( 2 << CC2420_RXCTRL1_RXMIX_CURRENT ) );

		writeTxctrl();
	}
	return SUCCESS;
}


async command error_t RadioPower.stopOscillator() {
	atomic {
		if ( m_state != S_XOSC_STARTED ) {
			return FAIL;
		}
		m_state = S_VREG_STARTED;
		call SXOSCOFF.strobe();
	}
	return SUCCESS;
}

async command error_t RadioPower.rxOn() {
	atomic {
		if ( m_state != S_XOSC_STARTED ) {
			return FAIL;
		}
		call SRXON.strobe();
	}
	return SUCCESS;
}

async command error_t RadioPower.rfOff() {
	atomic {  
		if ( m_state != S_XOSC_STARTED ) {
			return FAIL;
		}
		call SRFOFF.strobe();
	}
	return SUCCESS;
}

/***************** RadioConfig Commands ****************/
command uint8_t RadioConfig.getChannel() {
	atomic return m_channel;
}

command void RadioConfig.setChannel( uint8_t channel ) {
	atomic m_channel = channel;
}

async command uint16_t RadioConfig.getShortAddr() {
	atomic return m_short_addr;
}

command void RadioConfig.setShortAddr( uint16_t addr ) {
	atomic m_short_addr = addr;
}

async command uint16_t RadioConfig.getPanAddr() {
	atomic return m_pan;
}

command void RadioConfig.setPanAddr( uint16_t pan ) {
	atomic m_pan = pan;
}

/**
 * Sync must be called to commit software parameters configured on
 * the microcontroller (through the RadioConfig interface) to the
 * CC2420 radio chip.
 */
command error_t RadioConfig.sync() {
	atomic {
		if ( m_sync_busy ) {
			return FAIL;
		}
      
		m_sync_busy = TRUE;
		if ( m_state == S_XOSC_STARTED ) {
			call SyncResource.request();
		} else {
			post syncDone();
		}
	}
	return SUCCESS;
}

/**
 * @param enableAddressRecognition TRUE to turn address recognition on
 * @param useHwAddressRecognition TRUE to perform address recognition first
 *     in hardware. This doesn't affect software address recognition. The
 *     driver must sync with the chip after changing this value.
 */
command void RadioConfig.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
	atomic {
		addressRecognition = enableAddressRecognition;
		hwAddressRecognition = useHwAddressRecognition;
	}
}
  
/**
 * @return TRUE if address recognition is enabled
 */
async command bool RadioConfig.isAddressRecognitionEnabled() {
	atomic return addressRecognition;
}
  
/**
 * @return TRUE if address recognition is performed first in hardware.
 */
async command bool RadioConfig.isHwAddressRecognitionDefault() {
	atomic return hwAddressRecognition;
}
  

/**
 * Sync must be called for acknowledgement changes to take effect
 * @param enableAutoAck TRUE to enable auto acknowledgements
 * @param hwAutoAck TRUE to default to hardware auto acks, FALSE to
 *     default to software auto acknowledgements
 */
command void RadioConfig.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
	atomic autoAckEnabled = enableAutoAck;
	atomic hwAutoAckDefault = hwAutoAck;
}
  
/**
 * @return TRUE if hardware auto acks are the default, FALSE if software
 *     acks are the default
 */
async command bool RadioConfig.isHwAutoAckDefault() {
	atomic return hwAutoAckDefault;    
}
  
/**
 * @return TRUE if auto acks are enabled
 */
async command bool RadioConfig.isAutoAckEnabled() {
	atomic return autoAckEnabled;
}
  
  
/***************** Spi Resources Events ****************/
event void SyncResource.granted() {
	call CSN.clr();
	call SRFOFF.strobe();
	writeFsctrl();
	writeMdmctrl0();
	writeId();
	call CSN.set();
	call CSN.clr();
	call SRXON.strobe();
	call CSN.set();
	call SyncResource.release();
	post syncDone();
}

event void SpiResource.granted() {
	call CSN.clr();
	signal RadioResource.granted();
}

  
/***************** StartupTimer Events ****************/
async event void StartupTimer.fired() {
	if ( m_state == S_VREG_STARTING ) {
		m_state = S_VREG_STARTED;
		call RSTN.clr();
		call RSTN.set();
		signal RadioPower.startVRegDone();
	}
}

/***************** InterruptCCA Events ****************/
async event void InterruptCCA.fired() {
	m_state = S_XOSC_STARTED;
	call InterruptCCA.disable();
	call IOCFG1.write( 0 );
	writeId();
	call CSN.set();
	call CSN.clr();
	signal RadioPower.startOscillatorDone();
}
 
/***************** ActiveMessageAddress Events ****************/
async event void ActiveMessageAddress.changed() {
	atomic {
		m_short_addr = call ActiveMessageAddress.amAddress();
		m_pan = call ActiveMessageAddress.amGroup();
	}
	post sync();
}
  
/***************** Tasks ****************/
/**
 * Attempt to synchronize our current settings with the CC2420
 */
task void sync() {
	call RadioConfig.sync();
}
  
task void syncDone() {
	atomic m_sync_busy = FALSE;
	signal RadioConfig.syncDone( SUCCESS );
}
  
  
/***************** Functions ****************/
/**
 * Write teh FSCTRL register
 */
void writeFsctrl() {
	uint8_t channel;
    
	atomic {
		channel = m_channel;
	}
    
	call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
		( ( (channel - 11)*5+357 ) << CC2420_FSCTRL_FREQ ) );
}

/**
 * Write the MDMCTRL0 register
 * Disabling hardware address recognition improves acknowledgment success
 * rate and low power communications reliability by causing the local node
 * to do work while the real destination node of the packet is acknowledging.
 */
void writeMdmctrl0() {
	atomic {
		call MDMCTRL0.write( ( 1 << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
			( ((addressRecognition && hwAddressRecognition) ? 1 : 0) << CC2420_MDMCTRL0_ADR_DECODE ) |
			( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
			( 3 << CC2420_MDMCTRL0_CCA_MOD ) |
			( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
			( (autoAckEnabled && hwAutoAckDefault) << CC2420_MDMCTRL0_AUTOACK ) |
			( 0 << CC2420_MDMCTRL0_AUTOACK ) |
			( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );
	}
	// Jon Green:
	// MDMCTRL1.CORR_THR is defaulted to 20 instead of 0 like the datasheet says
	// If we add in changes to MDMCTRL1, be sure to include this fix.
}
  
/**
 * Write the PANID register
 */
void writeId() {
	nxle_uint16_t id[ 6 ];

	atomic {
		/* Eui-64 is stored in big endian */
		memcpy((uint8_t *)id, m_ext_addr.data, 8);
		id[ 4 ] = m_pan;
		id[ 5 ] = m_short_addr;
	}

	call IEEEADR.write(0, (uint8_t *)&id, 12);
}

/* Write the Transmit control register. This
   is needed so acknowledgments are sent at the
   correct transmit power even if a node has
   not sent a packet (Google Code Issue #27) -pal */

void writeTxctrl() {
	atomic {
		call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
			( 3 << CC2420_TXCTRL_PA_CURRENT ) |
			( 1 << CC2420_TXCTRL_RESERVED ) |
			( (m_tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
	}
}
/***************** Defaults ****************/
default event void RadioConfig.syncDone( error_t error ) {
}

}
