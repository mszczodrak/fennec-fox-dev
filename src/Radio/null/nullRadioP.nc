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
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface RadioSend;
provides interface ReceiveIndicator as PacketIndicator;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

uses interface nullRadioParams;
}

implementation {

uint8_t channel;
uint8_t mgmt = FALSE;
norace uint8_t state = S_STOPPED;
norace message_t *m;

task void start_done() {
	state = S_STARTED;

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
	signal RadioControl.stopDone(SUCCESS);
	if (mgmt == TRUE) {
		signal Mgmt.stopDone(SUCCESS);
		mgmt = FALSE;
	}
}

command error_t Mgmt.start() {
	dbg("Radio", "nullRadio Mgmt.start()");
	mgmt = TRUE;
	call RadioControl.start();
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("Radio", "nullRadio Mgmt.stop()");
	mgmt = TRUE;
	call RadioControl.stop();
	return SUCCESS;
}

command error_t RadioControl.start() {
	if (state == S_STOPPED) {
		state = S_STARTING;
		post start_done();
		return SUCCESS;

	} else if(state == S_STARTED) {
		post start_done();
		return EALREADY;

    } else if(state == S_STARTING) {
      return SUCCESS;
    }

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
	return FALSE;
}

async command bool EnergyIndicator.isReceiving() {
	return FALSE;
}

async command bool PacketIndicator.isReceiving() {
	return FALSE;
}

task void load_done() {
	signal RadioBuffer.loadDone(m, SUCCESS);
}

async command error_t RadioBuffer.load(message_t* msg) {
	dbg("Radio", "nullRadio RadioBuffer.load(0x%1x)", msg);
	m = msg;
	post load_done();
	return SUCCESS;
}

task void send_done() {
	signal RadioSend.sendDone(m, SUCCESS);
}

async command error_t RadioSend.send(message_t* msg, bool useCca) {
	dbg("Radio", "nullRadio RadioBuffer.send(0x%1x)", msg, useCca);
	post send_done();
	return SUCCESS;
}

async command error_t RadioSend.cancel(message_t *msg) {
	dbg("Radio", "nullRadio RadioBuffer.cancel(0x%1x)", msg);
	return SUCCESS;
}

async command uint8_t RadioPacket.maxPayloadLength() {
	dbg("Radio", "nullRadio RadioBuffer.maxPayloadLength()");
	return 128;
}

async command void* RadioPacket.getPayload(message_t* msg, uint8_t len) {
	dbg("Radio", "nullRadio RadioBuffer.getPayload(0x%1x, %d)", msg, len);
	return msg->data;
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

