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

