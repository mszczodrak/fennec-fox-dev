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

