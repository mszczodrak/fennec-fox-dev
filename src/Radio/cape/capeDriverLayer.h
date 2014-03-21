/*
 * Copyright (c) 2010, Vanderbilt University
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
 
#ifndef __CAPE_DRIVERLAYER_H__
#define __CAPE_DRIVERLAYER_H__


typedef nx_struct cape_header_t
{
	nxle_uint8_t length;
} cape_header_t;

typedef struct cape_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}; 
} cape_metadata_t; 

enum cape_timing_enums {
	CAPE_SYMBOL_TIME = 16, // 16us	
	IDLE_2_RX_ON_TIME = 12 * CAPE_SYMBOL_TIME, 
	PD_2_IDLE_TIME = 860, // .86ms
	STROBE_TO_TX_ON_TIME = 12 * CAPE_SYMBOL_TIME, 
	// TX SFD delay is computed as follows:
	// a.) STROBE_TO_TX_ON_TIME is required for preamble transmission to 
	// start after TX strobe is issued
	// b.) the SFD byte is the 5th byte transmitted (10 symbol periods)
	// c.) there's approximately a 25us delay between the strobe and reading
	// the timer register
	TX_SFD_DELAY = STROBE_TO_TX_ON_TIME + 10 * CAPE_SYMBOL_TIME - 25,
	// TX SFD is captured in hardware
	RX_SFD_DELAY = 0,
};

enum cape_reg_access_enums {
	CAPE_CMD_REGISTER_MASK = 0x3f,
	CAPE_CMD_REGISTER_READ = 0x40,
	CAPE_CMD_REGISTER_WRITE = 0x00,
	CAPE_CMD_TXRAM_WRITE	= 0x80,
};

typedef union cape_status {
	uint16_t value;
	struct {
	  unsigned  reserved0:1;
	  unsigned  rssi_valid:1;
	  unsigned  lock:1;
	  unsigned  tx_active:1;
	  
	  unsigned  enc_busy:1;
	  unsigned  tx_underflow:1;
	  unsigned  xosc16m_stable:1;
	  unsigned  reserved7:1;
	};
} cape_status_t;

typedef union cape_iocfg0 {
	uint16_t value;
	struct {
	  unsigned  fifop_thr:7;
	  unsigned  cca_polarity:1;
	  unsigned  sfd_polarity:1;
	  unsigned  fifop_polarity:1;
	  unsigned  fifo_polarity:1;
	  unsigned  bcn_accept:1;
	  unsigned  reserved:4; // write as 0
	} f;
} cape_iocfg0_t;

// TODO: make sure that we avoid wasting RAM
static const cape_iocfg0_t cape_iocfg0_default = {.f.fifop_thr = 64, .f.cca_polarity = 0, .f.sfd_polarity = 0, .f.fifop_polarity = 0, .f.fifo_polarity = 0, .f.bcn_accept = 0, .f.reserved = 0};

typedef union cape_iocfg1 {
	uint16_t value;
	struct {
	  unsigned  ccamux:5;
	  unsigned  sfdmux:5;
	  unsigned  hssd_src:3;
	  unsigned  reserved:3; // write as 0
	} f;
} cape_iocfg1_t;

static const cape_iocfg1_t cape_iocfg1_default = {.value = 0};

typedef union cape_fsctrl {
	uint16_t value;
	struct {
	  unsigned  freq:10;
	  unsigned  lock_status:1;
	  unsigned  lock_length:1;
	  unsigned  cal_running:1;
	  unsigned  cal_done:1;
	  unsigned  lock_thr:2;
	} f;
} cape_fsctrl_t;

static const cape_fsctrl_t cape_fsctrl_default = {.f.lock_thr = 1, .f.freq = 357, .f.lock_status = 0, .f.lock_length = 0, .f.cal_running = 0, .f.cal_done = 0};

typedef union cape_mdmctrl0 {
	uint16_t value;
	struct {
	  unsigned  preamble_length:4;
	  unsigned  autoack:1;
	  unsigned  autocrc:1;
	  unsigned  cca_mode:2;
	  unsigned  cca_hyst:3;
	  unsigned  adr_decode:1;
	  unsigned  pan_coordinator:1;
	  unsigned  reserved_frame_mode:1;
	  unsigned  reserved:2;
	} f;
} cape_mdmctrl0_t;

static const cape_mdmctrl0_t cape_mdmctrl0_default = {.f.preamble_length = 2, .f.autocrc = 1, .f.cca_mode = 3, .f.cca_hyst = 2, .f.adr_decode = 1};

typedef union cape_txctrl {
	uint16_t value;
	struct {
	  unsigned  pa_level:5;
	  unsigned reserved:1;
	  unsigned pa_current:3;
	  unsigned txmix_current:2;
	  unsigned txmix_caparray:2;
  	  unsigned tx_turnaround:1;
  	  unsigned txmixbuf_cur:2;
	} f;
} cape_txctrl_t;

static const cape_txctrl_t cape_txctrl_default = {.f.pa_level = 31, .f.reserved = 1, .f.pa_current = 3, .f.tx_turnaround = 1, .f.txmixbuf_cur = 2};


#ifndef CAPE_DEF_CHANNEL
#define CAPE_DEF_CHANNEL 11
#endif

#ifndef CAPE_DEF_RFPOWER
#define CAPE_DEF_RFPOWER 31
#endif

enum {
	CAPE_TX_PWR_MASK = 0x1f,
	CAPE_CHANNEL_MASK = 0x1f,
};

enum cape_config_reg_enums {
  CAPE_SNOP = 0x00,
  CAPE_SXOSCON = 0x01,
  CAPE_STXCAL = 0x02,
  CAPE_SRXON = 0x03,
  CAPE_STXON = 0x04,
  CAPE_STXONCCA = 0x05,
  CAPE_SRFOFF = 0x06,
  CAPE_SXOSCOFF = 0x07,
  CAPE_SFLUSHRX = 0x08,
  CAPE_SFLUSHTX = 0x09,
  CAPE_SACK = 0x0a,
  CAPE_SACKPEND = 0x0b,
  CAPE_SRXDEC = 0x0c,
  CAPE_STXENC = 0x0d,
  CAPE_SAES = 0x0e,
  CAPE_MAIN = 0x10,
  CAPE_MDMCTRL0 = 0x11,
  CAPE_MDMCTRL1 = 0x12,
  CAPE_RSSI = 0x13,
  CAPE_SYNCWORD = 0x14,
  CAPE_TXCTRL = 0x15,
  CAPE_RXCTRL0 = 0x16,
  CAPE_RXCTRL1 = 0x17,
  CAPE_FSCTRL = 0x18,
  CAPE_SECCTRL0 = 0x19,
  CAPE_SECCTRL1 = 0x1a,
  CAPE_BATTMON = 0x1b,
  CAPE_IOCFG0 = 0x1c,
  CAPE_IOCFG1 = 0x1d,
  CAPE_MANFIDL = 0x1e,
  CAPE_MANFIDH = 0x1f,
  CAPE_FSMTC = 0x20,
  CAPE_MANAND = 0x21,
  CAPE_MANOR = 0x22,
  CAPE_AGCCTRL = 0x23,
  CAPE_AGCTST0 = 0x24,
  CAPE_AGCTST1 = 0x25,
  CAPE_AGCTST2 = 0x26,
  CAPE_FSTST0 = 0x27,
  CAPE_FSTST1 = 0x28,
  CAPE_FSTST2 = 0x29,
  CAPE_FSTST3 = 0x2a,
  CAPE_RXBPFTST = 0x2b,
  CAPE_FSMSTATE = 0x2c,
  CAPE_ADCTST = 0x2d,
  CAPE_DACTST = 0x2e,
  CAPE_TOPTST = 0x2f,
  CAPE_TXFIFO = 0x3e,
  CAPE_RXFIFO = 0x3f,
};

enum cape_ram_addr_enums {
  CAPE_RAM_TXFIFO = 0x000,
  CAPE_RAM_TXFIFO_END = 0x7f,  
  CAPE_RAM_RXFIFO = 0x080,
  CAPE_RAM_KEY0 = 0x100,
  CAPE_RAM_RXNONCE = 0x110,
  CAPE_RAM_SABUF = 0x120,
  CAPE_RAM_KEY1 = 0x130,
  CAPE_RAM_TXNONCE = 0x140,
  CAPE_RAM_CBCSTATE = 0x150,
  CAPE_RAM_IEEEADR = 0x160,
  CAPE_RAM_PANID = 0x168,
  CAPE_RAM_SHORTADR = 0x16a,
};


#endif // __CAPE_DRIVERLAYER_H__
