/*
 *  Null radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Network: Null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "glossyRadio.h"
#include "glossy.h"
#include "rtimer.h"
#include "msp430def.h"

module glossyRadioP @safe() {
  provides interface Mgmt;
  provides interface Receive as RadioReceive;
  provides interface ModuleStatus as RadioStatus;

  uses interface glossyRadioParams;

  provides interface Resource as RadioResource;
  provides interface RadioConfig;
  provides interface RadioPower;
  provides interface Read<uint16_t> as ReadRssi;

  provides interface StdControl as RadioControl;

  provides interface RadioTransmit;

  provides interface ReceiveIndicator as PacketIndicator;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;
}

implementation {

  uint8_t channel;

#include "spi.c"
#include "watchdog.c"
#include "msp430.c"

/*---------------------------------------------------------------------------*/
/**
 * Delay the CPU for a multiple of 2.83 us.
 */
void
clock_delay(unsigned int i)
{
  asm("add #-1, r15");
  asm("jnz $-2");
  /*
   * This means that delay(i) will delay the CPU for CONST + 3x
   * cycles. On a 2.4756 CPU, this means that each i adds 1.22us of
   * delay.
   *
   * do {
   *   --i;
   * } while(i > 0);
   */
}



/* Glossy vars */

static uint8_t initiator, sync, rx_cnt, tx_cnt, tx_max;
static uint8_t *data, *packet;
static uint8_t data_len, packet_len;
static uint8_t bytes_read, tx_relay_cnt_last;
static volatile uint8_t state;
static rtimer_clock_t t_rx_start, t_rx_stop, t_tx_start, t_tx_stop;
static rtimer_clock_t t_rx_timeout;
static rtimer_clock_t T_irq;
static unsigned short ie1, ie2, p1ie, p2ie, tbiv;

static rtimer_clock_t T_slot_h, T_rx_h, T_w_rt_h, T_tx_h, T_w_tr_h, t_ref_l, T_offset_h, t_first_rx_l;
#if GLOSSY_SYNC_WINDOW
static unsigned long T_slot_h_sum;
static uint8_t win_cnt;
#endif /* GLOSSY_SYNC_WINDOW */
static uint8_t relay_cnt, t_ref_l_updated;

/* */


/* --------------------------- Radio functions ---------------------- */
static inline void radio_flush_tx(void) {
        FASTSPI_STROBE(CC2420_SFLUSHTX);
}

static inline uint8_t radio_status(void) {
        uint8_t status;
        FASTSPI_UPD_STATUS(status);
        return status;
}

static inline void radio_on(void) {
        FASTSPI_STROBE(CC2420_SRXON);
        while(!(radio_status() & (BV(CC2420_XOSC16M_STABLE))));
        ENERGEST_ON(ENERGEST_TYPE_LISTEN);
}

static inline void radio_off(void) {
#if ENERGEST_CONF_ON
        if (energest_current_mode[ENERGEST_TYPE_TRANSMIT]) {
                ENERGEST_OFF(ENERGEST_TYPE_TRANSMIT);
        }
        if (energest_current_mode[ENERGEST_TYPE_LISTEN]) {
                ENERGEST_OFF(ENERGEST_TYPE_LISTEN);
        }
#endif /* ENERGEST_CONF_ON */
        FASTSPI_STROBE(CC2420_SRFOFF);
}

static inline void radio_flush_rx(void) {
        uint8_t dummy;
        FASTSPI_READ_FIFO_BYTE(dummy);
        FASTSPI_STROBE(CC2420_SFLUSHRX);
        FASTSPI_STROBE(CC2420_SFLUSHRX);
}

static inline void radio_abort_rx(void) {
        state = GLOSSY_STATE_ABORTED;
        radio_flush_rx();
}

static inline void radio_abort_tx(void) {
        FASTSPI_STROBE(CC2420_SRXON);
#if ENERGEST_CONF_ON
        if (energest_current_mode[ENERGEST_TYPE_TRANSMIT]) {
                ENERGEST_OFF(ENERGEST_TYPE_TRANSMIT);
                ENERGEST_ON(ENERGEST_TYPE_LISTEN);
        }
#endif /* ENERGEST_CONF_ON */
        radio_flush_rx();
}

static inline void radio_start_tx(void) {
        FASTSPI_STROBE(CC2420_STXON);
#if ENERGEST_CONF_ON
        ENERGEST_OFF(ENERGEST_TYPE_LISTEN);
        ENERGEST_ON(ENERGEST_TYPE_TRANSMIT);
#endif /* ENERGEST_CONF_ON */
}

static inline void radio_write_tx(void) {
        FASTSPI_WRITE_FIFO(packet, packet_len - 1);
}

/* --------------------------- SFD interrupt ------------------------ */
interrupt(TIMERB1_VECTOR)
timerb1_interrupt(void)
{
        // compute the variable part of the delay with which the interrupt has been served
        T_irq = ((RTIMER_NOW_DCO() - TBCCR1) - 24) << 1;

        if (state == GLOSSY_STATE_RECEIVING && !SFD_IS_1) {
                // packet reception has finished
                // T_irq in [0,...,8]
                if (T_irq <= 8) {
                        // NOPs (variable number) to compensate for the interrupt service delay (sec. 5.2)
                        asm volatile("add %[d], r0" : : [d] "m" (T_irq));
                        asm volatile("nop");                                            // irq_delay = 0
                        asm volatile("nop");                                            // irq_delay = 2
                        asm volatile("nop");                                            // irq_delay = 4
                        asm volatile("nop");                                            // irq_delay = 6
                        asm volatile("nop");                                            // irq_delay = 8
                        // NOPs (fixed number) to compensate for HW variations (sec. 5.3)
                        // (asynchronous MCU and radio clocks)
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        asm volatile("nop");
                        // relay the packet
                        radio_start_tx();
                        // read TBIV to clear IFG
                        tbiv = TBIV;
                        glossy_end_rx();
                } else {
                        // interrupt service delay is too high: do not relay the packet
                        radio_flush_rx();
                        state = GLOSSY_STATE_WAITING;
                        // read TBIV to clear IFG
   tbiv = TBIV;
                }
        } else {
                // read TBIV to clear IFG
                tbiv = TBIV;
                if (state == GLOSSY_STATE_WAITING && SFD_IS_1) {
                        // packet reception has started
                        glossy_begin_rx();
                } else {
                        if (state == GLOSSY_STATE_RECEIVED && SFD_IS_1) {
                                // packet transmission has started
                                glossy_begin_tx();
                        } else {
                                if (state == GLOSSY_STATE_TRANSMITTING && !SFD_IS_1) {
                                        // packet transmission has finished
                                        glossy_end_tx();
                                } else {
                                        if (state == GLOSSY_STATE_ABORTED) {
                                                // packet reception has been aborted
                                                state = GLOSSY_STATE_WAITING;
                                        } else {
                                                if ((state == GLOSSY_STATE_WAITING) && (tbiv == TBIV_CCR4)) {
                                                        // initiator timeout
                                                        if (rx_cnt == 0) {
                                                                // no packets received so far: send the packet again
                                                                tx_cnt = 0;
                                                                // set the packet length field to the appropriate value
                                                                GLOSSY_LEN_FIELD = packet_len;
                                                                // set the header field
                                                                GLOSSY_HEADER_FIELD = GLOSSY_HEADER;
                                                                if (sync) {
                                                                        // do not use this packet for synchronization
                                                                        GLOSSY_RELAY_CNT_FIELD = MAX_VALID_RELAY_CNT;
                                                                }
                                                                // copy the application data to the data field
                                                                memcpy(&GLOSSY_DATA_FIELD, data, data_len);
                                                                // set Glossy state
                                                                state = GLOSSY_STATE_RECEIVED;
                                                                // write the packet to the TXFIFO
                                                                radio_write_tx();
                                                                // start another transmission
                                                                radio_start_tx();
                                                                // schedule the timeout again
                                                                glossy_schedule_initiator_timeout();
                                                        } else {
                                                                // at least one packet has been received: just stop the timeout
                                                                glossy_stop_initiator_timeout();
                                                        }
                                                } else {
                                                        if (tbiv == TBIV_CCR5) {
                                                                // rx timeout
                                                                if (state == GLOSSY_STATE_RECEIVING) {
                                                                        // we are still trying to receive a packet: abort the reception
                                                                        radio_abort_rx();
#if GLOSSY_DEBUG
                                                                        rx_timeout++;
#endif /* GLOSSY_DEBUG */
                                                                }
                                                                // stop the timeout
                                                                glossy_stop_rx_timeout();
                                                        } else {
                                                                if (state != GLOSSY_STATE_OFF) {
                                                                        // something strange is going on: go back to the waiting state
                                                                        radio_flush_rx();
                                                                        state = GLOSSY_STATE_WAITING;
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
}

/* --------------------------- Glossy process ----------------------- */


/*
PROCESS(glossy_process, "Glossy busy-waiting process");
PROCESS_THREAD(glossy_process, ev, data) {
        PROCESS_BEGIN();

        while (1) {
                PROCESS_WAIT_EVENT_UNTIL(ev == PROCESS_EVENT_POLL);
                // prevent the Contiki main cycle to enter the LPM mode or
                // any other process to run while Glossy is running
                while (GLOSSY_IS_ON());
        }

        PROCESS_END();
}
*/

static inline void glossy_disable_other_interrupts(void) {
    int s = splhigh();
        ie1 = IE1;
        ie2 = IE2;
        p1ie = P1IE;
        p2ie = P2IE;
        IE1 = 0;
        IE2 = 0;
        P1IE = 0;
        P2IE = 0;
        CACTL1 &= ~CAIE;
        DMA0CTL &= ~DMAIE;
        DMA1CTL &= ~DMAIE;
        DMA2CTL &= ~DMAIE;
        // disable etimer interrupts
        TACCTL1 &= ~CCIE;
        TBCCTL0 = 0;
        DISABLE_FIFOP_INT();
        CLEAR_FIFOP_INT();
        SFD_CAP_INIT(CM_BOTH);
        ENABLE_SFD_INT();
        // stop Timer B
        TBCTL = 0;
        // Timer B sourced by the DCO
        TBCTL = TBSSEL1;
        // start Timer B
        TBCTL |= MC1;
    splx(s);
    watchdog_stop();
}

static inline void glossy_enable_other_interrupts(void) {
        int s = splhigh();
        IE1 = ie1;
        IE2 = ie2;
        P1IE = p1ie;
        P2IE = p2ie;
        // enable etimer interrupts
        TACCTL1 |= CCIE;
#if COOJA
        if (TACCTL1 & CCIFG) {
                etimer_interrupt();
        }
#endif
        DISABLE_SFD_INT();
        CLEAR_SFD_INT();
        FIFOP_INT_INIT();
        ENABLE_FIFOP_INT();
        // stop Timer B
        TBCTL = 0;
        // Timer B sourced by the 32 kHz
        TBCTL = TBSSEL0;
        // start Timer B
        TBCTL |= MC1;
    splx(s);
    watchdog_start();
}


/* --------------------------- Main interface ----------------------- */
void glossy_start(uint8_t *data_, uint8_t data_len_, uint8_t initiator_,
                uint8_t sync_, uint8_t tx_max_) {
        // copy function arguments to the respective Glossy variables
        data = data_;
        data_len = data_len_;
        initiator = initiator_;
        sync = sync_;
        tx_max = tx_max_;
        // disable all interrupts that may interfere with Glossy
        glossy_disable_other_interrupts();
        // initialize Glossy variables
        tx_cnt = 0;
        rx_cnt = 0;

        // set Glossy packet length, with or without relay counter depending on the sync flag value
        packet_len = (sync) ?
                        data_len + FOOTER_LEN + GLOSSY_RELAY_CNT_LEN + GLOSSY_HEADER_LEN :
                        data_len + FOOTER_LEN + GLOSSY_HEADER_LEN;
        // allocate memory for the temporary buffer
        packet = (uint8_t *) malloc(packet_len + 1);
        // set the packet length field to the appropriate value
        GLOSSY_LEN_FIELD = packet_len;
        // set the header field
        GLOSSY_HEADER_FIELD = GLOSSY_HEADER;
        if (initiator) {
                // initiator: copy the application data to the data field
                memcpy(&GLOSSY_DATA_FIELD, data, data_len);
                // set Glossy state
                state = GLOSSY_STATE_RECEIVED;
        } else {
                // receiver: set Glossy state
                state = GLOSSY_STATE_WAITING;
        }
        if (sync) {
                // set the relay_cnt field to 0
                GLOSSY_RELAY_CNT_FIELD = 0;
                // the reference time has not been updated yet
                t_ref_l_updated = 0;
        }

#if !COOJA
        // resynchronize the DCO
        msp430_sync_dco();
#endif /* COOJA */

        // flush radio buffers
        radio_flush_rx();
        radio_flush_tx();
        if (initiator) {
                // write the packet to the TXFIFO
                radio_write_tx();
                // start the first transmission
                radio_start_tx();
                // schedule the initiator timeout
                glossy_schedule_initiator_timeout();
        } else {
                // turn on the radio
                radio_on();
        }
        // activate the Glossy busy waiting process
        //process_poll(&glossy_process);
}

uint8_t glossy_stop(void) {
        // stop the initiator timeout, in case it is still active
        glossy_stop_initiator_timeout();
        // turn off the radio
        radio_off();

        // flush radio buffers
        radio_flush_rx();
        radio_flush_tx();

        state = GLOSSY_STATE_OFF;
        // re-enable non Glossy-related interrupts
        glossy_enable_other_interrupts();
        // deallocate memory for the temporary buffer
        free(packet);
        // return the number of times the packet has been received
        return rx_cnt;
}

uint8_t get_rx_cnt(void) {
        return rx_cnt;
}

uint8_t get_relay_cnt(void) {
        return relay_cnt;
}

rtimer_clock_t get_T_slot_h(void) {
        return T_slot_h;
}

uint8_t is_t_ref_l_updated(void) {
        return t_ref_l_updated;
}

rtimer_clock_t get_t_first_rx_l(void) {
        return t_first_rx_l;
}

rtimer_clock_t get_t_ref_l(void) {
        return t_ref_l;
}

void set_t_ref_l(rtimer_clock_t t) {
        t_ref_l = t;
}

void set_t_ref_l_updated(uint8_t updated) {
        t_ref_l_updated = updated;
}

uint8_t get_state(void) {
        return state;
}


static inline void estimate_slot_length(rtimer_clock_t t_rx_stop_tmp) {
        // estimate slot length if rx_cnt > 1
        // and we have received a packet immediately after our last transmission
        if ((rx_cnt > 1) && (GLOSSY_RELAY_CNT_FIELD == (tx_relay_cnt_last + 2))) {
                T_w_rt_h = t_tx_start - t_rx_stop;
                T_tx_h = t_tx_stop - t_tx_start;
                T_w_tr_h = t_rx_start - t_tx_stop;
                T_rx_h = t_rx_stop_tmp - t_rx_start;
                rtimer_clock_t T_slot_h_tmp = (T_tx_h + T_w_tr_h + T_rx_h + T_w_rt_h) / 2;
#if GLOSSY_SYNC_WINDOW
                T_slot_h_sum += T_slot_h_tmp;
                if ((++win_cnt) == GLOSSY_SYNC_WINDOW) {
                        // update the slot length estimation
                        T_slot_h = T_slot_h_sum / GLOSSY_SYNC_WINDOW;
                        // halve the counters
                        T_slot_h_sum /= 2;
                        win_cnt /= 2;
                } else {
                        if (win_cnt == 1) {
                                // at the beginning, use the first estimation of the slot length
                                T_slot_h = T_slot_h_tmp;
                        }
                }
#else
                T_slot_h = T_slot_h_tmp;
#endif /* GLOSSY_SYNC_WINDOW */
        }
}


static inline void compute_sync_reference_time(void) {
#if COOJA
        rtimer_clock_t t_cap_l = RTIMER_NOW();
        rtimer_clock_t t_cap_h = RTIMER_NOW_DCO();
#else
        // capture the next low-frequency clock tick
        rtimer_clock_t t_cap_h, t_cap_l;
        CAPTURE_NEXT_CLOCK_TICK(t_cap_h, t_cap_l);
#endif /* COOJA */
        rtimer_clock_t T_rx_to_cap_h = t_cap_h - t_rx_start;
        unsigned long T_ref_to_rx_h = (GLOSSY_RELAY_CNT_FIELD - 1) * (unsigned long)T_slot_h;
        unsigned long T_ref_to_cap_h = T_ref_to_rx_h + (unsigned long)T_rx_to_cap_h;
        rtimer_clock_t T_ref_to_cap_l = 1 + T_ref_to_cap_h / CLOCK_PHI;
        // high-resolution offset of the reference time
        T_offset_h = (CLOCK_PHI - 1) - (T_ref_to_cap_h % CLOCK_PHI);
        // low-resolution value of the reference time
        t_ref_l = t_cap_l - T_ref_to_cap_l;
        relay_cnt = GLOSSY_RELAY_CNT_FIELD - 1;
        // the reference time has been updated
        t_ref_l_updated = 1;
}


/* ----------------------- Interrupt functions ---------------------- */
inline void glossy_begin_rx(void) {
        t_rx_start = TBCCR1;
        state = GLOSSY_STATE_RECEIVING;
        // Rx timeout: packet duration + 200 us
        // (packet duration: 32 us * packet_length, 1 DCO tick ~ 0.23 us)
        t_rx_timeout = t_rx_start + ((rtimer_clock_t)packet_len * 35 + 200) * 4;

        // wait until the FIFO pin is 1 (i.e., until the first byte is received)
        while (!FIFO_IS_1) {
                if (!RTIMER_CLOCK_LT(RTIMER_NOW_DCO(), t_rx_timeout)) {
                        radio_abort_rx();
#if GLOSSY_DEBUG
                        rx_timeout++;
#endif /* GLOSSY_DEBUG */
                        return;
                }
        };
        // read the first byte (i.e., the len field) from the RXFIFO
        FASTSPI_READ_FIFO_BYTE(GLOSSY_LEN_FIELD);
        // keep receiving only if it has the right length
        if (GLOSSY_LEN_FIELD != packet_len) {
                // packet with a wrong length: abort packet reception
                radio_abort_rx();
#if GLOSSY_DEBUG
                bad_length++;
#endif /* GLOSSY_DEBUG */
                return;
        }
        bytes_read = 1;

#if !COOJA
        // wait until the FIFO pin is 1 (i.e., until the second byte is received)
        while (!FIFO_IS_1) {
                if (!RTIMER_CLOCK_LT(RTIMER_NOW_DCO(), t_rx_timeout)) {
                        radio_abort_rx();
#if GLOSSY_DEBUG
                        rx_timeout++;
#endif /* GLOSSY_DEBUG */
                        return;
                }
        };
        // read the second byte (i.e., the header field) from the RXFIFO
        FASTSPI_READ_FIFO_BYTE(GLOSSY_HEADER_FIELD);
        // keep receiving only if it has the right header
        if (GLOSSY_HEADER_FIELD != GLOSSY_HEADER) {
                // packet with a wrong header: abort packet reception
                radio_abort_rx();
#if GLOSSY_DEBUG
                bad_header++;
#endif /* GLOSSY_DEBUG */
                return;
        }
        bytes_read = 2;
        if (packet_len > 8) {
                // if packet is longer than 8 bytes, read all bytes but the last 8
                while (bytes_read <= packet_len - 8) {
                        // wait until the FIFO pin is 1 (until one more byte is received)
                        while (!FIFO_IS_1) {
                                if (!RTIMER_CLOCK_LT(RTIMER_NOW_DCO(), t_rx_timeout)) {
                                        radio_abort_rx();
#if GLOSSY_DEBUG
                                        rx_timeout++;
#endif /* GLOSSY_DEBUG */
                                        return;
                                }
                        };
                        // read another byte from the RXFIFO
                        FASTSPI_READ_FIFO_BYTE(packet[bytes_read]);
                        bytes_read++;
                }
        }
#endif /* COOJA */
        glossy_schedule_rx_timeout();
}


inline void glossy_end_rx(void) {
        rtimer_clock_t t_rx_stop_tmp = TBCCR1;
        // read the remaining bytes from the RXFIFO
        FASTSPI_READ_FIFO_NO_WAIT(&packet[bytes_read], packet_len - bytes_read + 1);
        bytes_read = packet_len + 1;
#if COOJA
        if ((GLOSSY_CRC_FIELD & FOOTER1_CRC_OK) && (GLOSSY_HEADER_FIELD == GLOSSY_HEADER)) {
#else
        if (GLOSSY_CRC_FIELD & FOOTER1_CRC_OK) {
#endif /* COOJA */
                // packet correctly received
                if (sync) {
                        // increment relay_cnt field
                        GLOSSY_RELAY_CNT_FIELD++;
                }
                if (tx_cnt == tx_max) {
                        // no more Tx to perform: stop Glossy
                        radio_off();
                        state = GLOSSY_STATE_OFF;
                } else {
                        // write Glossy packet to the TXFIFO
                        radio_write_tx();
                        state = GLOSSY_STATE_RECEIVED;
                }
                if (rx_cnt == 0) {
                        // first successful reception: store current time
                        t_first_rx_l = RTIMER_NOW();
                }
                rx_cnt++;
                if (sync && (GLOSSY_RELAY_CNT_FIELD < MAX_VALID_RELAY_CNT)) {
                        estimate_slot_length(t_rx_stop_tmp);
                }
                t_rx_stop = t_rx_stop_tmp;
                if (initiator) {
                        // a packet has been successfully received: stop the initiator timeout
                        glossy_stop_initiator_timeout();
                }
        } else {
#if GLOSSY_DEBUG
                bad_crc++;
#endif /* GLOSSY_DEBUG */
                // packet corrupted, abort the transmission before it actually starts
                radio_abort_tx();
                state = GLOSSY_STATE_WAITING;
        }
}

inline void glossy_begin_tx(void) {
        t_tx_start = TBCCR1;
        state = GLOSSY_STATE_TRANSMITTING;
        tx_relay_cnt_last = GLOSSY_RELAY_CNT_FIELD;
        if ((!initiator) && (rx_cnt == 1)) {
                // copy the application data from the data field
                memcpy(data, &GLOSSY_DATA_FIELD, data_len);
        }
        if ((sync) && (T_slot_h) && (!t_ref_l_updated) && (rx_cnt) &&
                        (GLOSSY_RELAY_CNT_FIELD < MAX_VALID_RELAY_CNT)) {
                // compute the reference time after the first reception (higher accuracy)
                compute_sync_reference_time();
        }
}

inline void glossy_end_tx(void) {
        ENERGEST_OFF(ENERGEST_TYPE_TRANSMIT);
        ENERGEST_ON(ENERGEST_TYPE_LISTEN);
        t_tx_stop = TBCCR1;
        // stop Glossy if tx_cnt reached tx_max (and tx_max > 1 at the initiator, if sync is enabled)
        if ((++tx_cnt == tx_max) && ((!sync) || ((tx_max - initiator) > 0))) {
                radio_off();
                state = GLOSSY_STATE_OFF;
        } else {
                state = GLOSSY_STATE_WAITING;
        }
        radio_flush_tx();
}

/* ------------------------------ Timeouts -------------------------- */
inline void glossy_schedule_rx_timeout(void) {
        TBCCR5 = t_rx_timeout;
        TBCCTL5 = CCIE;
}

inline void glossy_stop_rx_timeout(void) {
        TBCCTL5 = 0;
}

inline void glossy_schedule_initiator_timeout(void) {
        TBCCR4 = RTIMER_NOW_DCO() + GLOSSY_INITIATOR_TIMEOUT;
        TBCCTL4 = CCIE;
}

inline void glossy_stop_initiator_timeout(void) {
        TBCCTL4 = 0;
}


































  command error_t Mgmt.start() {
    dbg("Radio", "Radio glossy starts\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbg("Radio", "Radio glossy stops\n");
    signal Mgmt.stopDone( SUCCESS );
    return SUCCESS;
  }

  command error_t RadioControl.start() {
    return SUCCESS;
  }

  command error_t RadioControl.stop() {
    return SUCCESS;
  }

  event void glossyRadioParams.receive_status(uint16_t status_flag) {
  }

  async command error_t RadioPower.startVReg() {
  }

  async command error_t RadioPower.stopVReg() {
  }

  async command error_t RadioPower.startOscillator() {
  }

  async command error_t RadioPower.stopOscillator() {
  }

  async command error_t RadioPower.rxOn() {
  }

  async command error_t RadioPower.rfOff() {
  }

  command uint8_t RadioConfig.getChannel() {
    return channel;
  }

  command void RadioConfig.setChannel( uint8_t new_channel ) {
    atomic channel = new_channel;
  }

  async command uint16_t RadioConfig.getShortAddr() {
    return TOS_NODE_ID;
  }

  command void RadioConfig.setShortAddr( uint16_t addr ) {
  }

  async command uint16_t RadioConfig.getPanAddr() {
    return TOS_NODE_ID;
  }

  command void RadioConfig.setPanAddr( uint16_t pan ) {
  }

  command error_t RadioConfig.sync() {
  }

  command void RadioConfig.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
  }

  async command bool RadioConfig.isAddressRecognitionEnabled() {
    return FALSE;
  }

  async command bool RadioConfig.isHwAddressRecognitionDefault() {
    return FALSE;
  }

  command void RadioConfig.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
  }

  async command bool RadioConfig.isHwAutoAckDefault() {
    return FALSE;
  }

  async command bool RadioConfig.isAutoAckEnabled() {
    return FALSE;
  }

  command error_t ReadRssi.read() {
    return FAIL;
  }


  async command bool ByteIndicator.isReceiving() {
    return FAIL;
  }

  async command bool EnergyIndicator.isReceiving() {
    return FAIL;
  }

  async command bool PacketIndicator.isReceiving() {
    return FAIL;
  }


  async command error_t RadioTransmit.load(message_t* msg) {
    return SUCCESS;
  }

  async command error_t RadioTransmit.send(message_t* msg, bool useCca) {
    return SUCCESS;
  }

  async command void RadioTransmit.cancel() {
  }

  async command error_t RadioResource.immediateRequest() {
    return SUCCESS;
  }

  async command error_t RadioResource.request() {
    return SUCCESS;
  }

  async command bool RadioResource.isOwner() {
    return SUCCESS;
  }

  async command error_t RadioResource.release() {
    return SUCCESS;
  }

}

