#ifndef __NULLRADIO_DRIVERLAYER_H__
#define __NULLRADIO_DRIVERLAYER_H__


typedef nx_struct nullRadio_header_t
{
	nxle_uint8_t length;
} nullRadio_header_t;

typedef struct nullRadio_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}; 
} nullRadio_metadata_t; 

enum nullRadio_timing_enums {
	NULLRADIO_SYMBOL_TIME = 16, // 16us	
	IDLE_2_RX_ON_TIME = 12 * NULLRADIO_SYMBOL_TIME, 
	PD_2_IDLE_TIME = 860, // .86ms
	STROBE_TO_TX_ON_TIME = 12 * NULLRADIO_SYMBOL_TIME, 
	// TX SFD delay is computed as follows:
	// a.) STROBE_TO_TX_ON_TIME is required for preamble transmission to 
	// start after TX strobe is issued
	// b.) the SFD byte is the 5th byte transmitted (10 symbol periods)
	// c.) there's approximately a 25us delay between the strobe and reading
	// the timer register
	TX_SFD_DELAY = STROBE_TO_TX_ON_TIME + 10 * NULLRADIO_SYMBOL_TIME - 25,
	// TX SFD is captured in hardware
	RX_SFD_DELAY = 0,
};

enum nullRadio_reg_access_enums {
	NULLRADIO_CMD_REGISTER_MASK = 0x3f,
	NULLRADIO_CMD_REGISTER_READ = 0x40,
	NULLRADIO_CMD_REGISTER_WRITE = 0x00,
	NULLRADIO_CMD_TXRAM_WRITE	= 0x80,
};

typedef union nullRadio_status {
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
} nullRadio_status_t;

typedef union nullRadio_iocfg0 {
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
} nullRadio_iocfg0_t;

// TODO: make sure that we avoid wasting RAM
static const nullRadio_iocfg0_t nullRadio_iocfg0_default = {.f.fifop_thr = 64, .f.cca_polarity = 0, .f.sfd_polarity = 0, .f.fifop_polarity = 0, .f.fifo_polarity = 0, .f.bcn_accept = 0, .f.reserved = 0};

typedef union nullRadio_iocfg1 {
	uint16_t value;
	struct {
	  unsigned  ccamux:5;
	  unsigned  sfdmux:5;
	  unsigned  hssd_src:3;
	  unsigned  reserved:3; // write as 0
	} f;
} nullRadio_iocfg1_t;

static const nullRadio_iocfg1_t nullRadio_iocfg1_default = {.value = 0};

typedef union nullRadio_fsctrl {
	uint16_t value;
	struct {
	  unsigned  freq:10;
	  unsigned  lock_status:1;
	  unsigned  lock_length:1;
	  unsigned  cal_running:1;
	  unsigned  cal_done:1;
	  unsigned  lock_thr:2;
	} f;
} nullRadio_fsctrl_t;

static const nullRadio_fsctrl_t nullRadio_fsctrl_default = {.f.lock_thr = 1, .f.freq = 357, .f.lock_status = 0, .f.lock_length = 0, .f.cal_running = 0, .f.cal_done = 0};

typedef union nullRadio_mdmctrl0 {
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
} nullRadio_mdmctrl0_t;

static const nullRadio_mdmctrl0_t nullRadio_mdmctrl0_default = {.f.preamble_length = 2, .f.autocrc = 1, .f.cca_mode = 3, .f.cca_hyst = 2, .f.adr_decode = 1};

typedef union nullRadio_txctrl {
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
} nullRadio_txctrl_t;

static const nullRadio_txctrl_t nullRadio_txctrl_default = {.f.pa_level = 31, .f.reserved = 1, .f.pa_current = 3, .f.tx_turnaround = 1, .f.txmixbuf_cur = 2};


#ifndef NULLRADIO_DEF_CHANNEL
#define NULLRADIO_DEF_CHANNEL 11
#endif

#ifndef NULLRADIO_DEF_RFPOWER
#define NULLRADIO_DEF_RFPOWER 31
#endif

enum {
	NULLRADIO_TX_PWR_MASK = 0x1f,
	NULLRADIO_CHANNEL_MASK = 0x1f,
};

enum nullRadio_config_reg_enums {
  NULLRADIO_SNOP = 0x00,
  NULLRADIO_SXOSCON = 0x01,
  NULLRADIO_STXCAL = 0x02,
  NULLRADIO_SRXON = 0x03,
  NULLRADIO_STXON = 0x04,
  NULLRADIO_STXONCCA = 0x05,
  NULLRADIO_SRFOFF = 0x06,
  NULLRADIO_SXOSCOFF = 0x07,
  NULLRADIO_SFLUSHRX = 0x08,
  NULLRADIO_SFLUSHTX = 0x09,
  NULLRADIO_SACK = 0x0a,
  NULLRADIO_SACKPEND = 0x0b,
  NULLRADIO_SRXDEC = 0x0c,
  NULLRADIO_STXENC = 0x0d,
  NULLRADIO_SAES = 0x0e,
  NULLRADIO_MAIN = 0x10,
  NULLRADIO_MDMCTRL0 = 0x11,
  NULLRADIO_MDMCTRL1 = 0x12,
  NULLRADIO_RSSI = 0x13,
  NULLRADIO_SYNCWORD = 0x14,
  NULLRADIO_TXCTRL = 0x15,
  NULLRADIO_RXCTRL0 = 0x16,
  NULLRADIO_RXCTRL1 = 0x17,
  NULLRADIO_FSCTRL = 0x18,
  NULLRADIO_SECCTRL0 = 0x19,
  NULLRADIO_SECCTRL1 = 0x1a,
  NULLRADIO_BATTMON = 0x1b,
  NULLRADIO_IOCFG0 = 0x1c,
  NULLRADIO_IOCFG1 = 0x1d,
  NULLRADIO_MANFIDL = 0x1e,
  NULLRADIO_MANFIDH = 0x1f,
  NULLRADIO_FSMTC = 0x20,
  NULLRADIO_MANAND = 0x21,
  NULLRADIO_MANOR = 0x22,
  NULLRADIO_AGCCTRL = 0x23,
  NULLRADIO_AGCTST0 = 0x24,
  NULLRADIO_AGCTST1 = 0x25,
  NULLRADIO_AGCTST2 = 0x26,
  NULLRADIO_FSTST0 = 0x27,
  NULLRADIO_FSTST1 = 0x28,
  NULLRADIO_FSTST2 = 0x29,
  NULLRADIO_FSTST3 = 0x2a,
  NULLRADIO_RXBPFTST = 0x2b,
  NULLRADIO_FSMSTATE = 0x2c,
  NULLRADIO_ADCTST = 0x2d,
  NULLRADIO_DACTST = 0x2e,
  NULLRADIO_TOPTST = 0x2f,
  NULLRADIO_TXFIFO = 0x3e,
  NULLRADIO_RXFIFO = 0x3f,
};

enum nullRadio_ram_addr_enums {
  NULLRADIO_RAM_TXFIFO = 0x000,
  NULLRADIO_RAM_TXFIFO_END = 0x7f,  
  NULLRADIO_RAM_RXFIFO = 0x080,
  NULLRADIO_RAM_KEY0 = 0x100,
  NULLRADIO_RAM_RXNONCE = 0x110,
  NULLRADIO_RAM_SABUF = 0x120,
  NULLRADIO_RAM_KEY1 = 0x130,
  NULLRADIO_RAM_TXNONCE = 0x140,
  NULLRADIO_RAM_CBCSTATE = 0x150,
  NULLRADIO_RAM_IEEEADR = 0x160,
  NULLRADIO_RAM_PANID = 0x168,
  NULLRADIO_RAM_SHORTADR = 0x16a,
};


#endif // __NULLRADIO_DRIVERLAYER_H__
