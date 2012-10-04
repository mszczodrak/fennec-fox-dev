/*
 *  null radio module for Fennec Fox platform.
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
 * Network: null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "nullRadio.h"

module nullRadioP @safe() {
  provides interface Mgmt;
  provides interface Receive as RadioReceive;
  provides interface ModuleStatus as RadioStatus;
  provides interface Resource as RadioResource;
  provides interface RadioConfig;
  provides interface RadioPower;
  provides interface Read<uint16_t> as ReadRssi;
  provides interface SplitControl as RadioControl;
  provides interface RadioTransmit;
  provides interface ReceiveIndicator as PacketIndicator;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;

  uses interface nullRadioParams;
}

implementation {

  uint8_t channel;
  uint8_t mgmt = FALSE;
  norace uint8_t state = S_STOPPED;

  task void start_done() {
    state = S_STARTED;
    printf("Radio task start done\n");
    printfflush();

    signal RadioControl.startDone(SUCCESS);
    if (mgmt == TRUE) {
      signal Mgmt.startDone(SUCCESS);
      mgmt = FALSE;
    }
  }

  task void finish_starting_radio() {
    post start_done();
  }

  task void stop_done() {
    state = S_STOPPED;
    printf("Radio task stop done\n");
    printfflush();
    signal RadioControl.stopDone(SUCCESS);
    if (mgmt == TRUE) {
      signal Mgmt.stopDone(SUCCESS);
      mgmt = FALSE;
    }
  }

  command error_t Mgmt.start() {
    printf("Mgmt start\n");
    mgmt = TRUE;
    call RadioControl.start();
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    printf("Mgmt stop\n");
    mgmt = TRUE;
    call RadioControl.stop();
    return SUCCESS;
  }

  command error_t RadioControl.start() {
    if (state == S_STOPPED) {
      state = S_STARTING;
      printf("Radio split start 1\n");
      printfflush();
      post start_done();
      return SUCCESS;

    } else if(state == S_STARTED) {
      printf("Radio split start 2\n");
      printfflush();
      post start_done();
      return EALREADY;

    } else if(state == S_STARTING) {
      printf("Radio split start 3\n");
      printfflush();
      return SUCCESS;
    }
    printf("Radio split start 4\n");
    printfflush();

    return EBUSY;
  }

  command error_t RadioControl.stop() {
    if (state == S_STARTED) {
      state = S_STOPPING;
      post stop_done();
      return SUCCESS;

    } else if(state == S_STOPPED) {
      post stop_done();
      return EALREADY;

    } else if(state == S_STOPPING) {
      return SUCCESS;
    }

    return EBUSY;
  }

  event void nullRadioParams.receive_status(uint16_t status_flag) {
  }

  async command error_t RadioPower.startVReg() {
    return SUCCESS;
  }

  async command error_t RadioPower.stopVReg() {
    return SUCCESS;
  }

  async command error_t RadioPower.startOscillator() {
    return SUCCESS;
  }

  async command error_t RadioPower.stopOscillator() {
    return SUCCESS;
  }

  async command error_t RadioPower.rxOn() {
    return SUCCESS;
  }

  async command error_t RadioPower.rfOff() {
    return SUCCESS;
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
    return SUCCESS;
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

