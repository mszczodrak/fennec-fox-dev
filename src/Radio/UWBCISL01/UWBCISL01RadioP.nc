/*
 *  Blinking application for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2011 Marcin Szczodrak
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
 * Application: UWB CISL
 * Author: Marcin Szczodrak
 * Date: 10/1/2011
 * Last Modified: 1/2/2012
 */


#include <Fennec.h>
#include "UWBCISL01Radio.h"

generic module UWBCISL01RadioP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;

  uses interface EnhantsPHY;

  uses interface Crc;

  uses interface GeneralIO as PinF1;
}

implementation {

  msg_t *message_send = NULL;
  msg_t *message_rcv = NULL;
  msg_t *new_msg = NULL;
  uint8_t uwbEnhants_state;

  task void task_loadDone_success();
  task void task_send_done();
  task void task_data_arrived();

  command error_t Mgmt.start() {
		call PinF1.makeOutput();
    atomic
    {
      message_rcv = signal Module.next_message();
      message_rcv->len = 0;
    }

    uwbEnhants_state = S_STARTING;
    call EnhantsPHY.init();
    call EnhantsPHY.set_direction_recv();
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Module.drop_message(message_rcv);
    uwbEnhants_state = S_STOPPED;
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t RadioCall.send(msg_t *msg) {
    uint8_t *data = (uint8_t*)&msg->data;
    uint8_t len = msg->len;
    error_t setdirErr = SUCCESS;

    if(uwbEnhants_state == S_LOADED)
    { 
      setdirErr = call EnhantsPHY.set_direction_send(); // senses the channel
      if(setdirErr == SUCCESS)
      {
        uwbEnhants_state = S_TRANSMITTING;
        call EnhantsPHY.phy_send(data, len);
        return SUCCESS;
      }
    }
    uwbEnhants_state = S_STOPPING;
    return FAIL;
  }

  command error_t RadioCall.resend(msg_t *msg) {
    uint8_t *data = (uint8_t*)&msg->data;
    uint8_t len = msg->len;
    error_t setdirErr = SUCCESS;

    if(uwbEnhants_state == S_STOPPING)
    { 
      setdirErr = call EnhantsPHY.set_direction_send(); // senses the channel
      if(setdirErr == SUCCESS)
      {
        uwbEnhants_state = S_TRANSMITTING;
        call EnhantsPHY.phy_send(data, len);
        return SUCCESS;
      }
    }
    return FAIL;
  }

  command uint8_t* RadioCall.getPayload(msg_t *msg) {
    return (uint8_t*)&msg->data;
  }

  command uint8_t RadioCall.getMaxSize(msg_t *msg) {
    return EUWB01_MAX_LENGTH;
  }

  command error_t RadioCall.load(msg_t *msg) {
    if((uwbEnhants_state == S_STARTING) || (uwbEnhants_state == S_STOPPING))
    {
      uwbEnhants_state = S_LOADING;

      /* Since there is no extra buffer, we just keep the pointer to message */
      message_send = msg;

      post task_loadDone_success();
      return SUCCESS;
    }
    uwbEnhants_state = S_STOPPING;
    return FAIL;
  }

  task void task_loadDone_success() {
    uwbEnhants_state = S_LOADED;
    signal RadioSignal.loadDone(message_send, SUCCESS);
  }

  command uint8_t RadioCall.sampleCCA(msg_t *msg) {
    return SUCCESS;
  }
 
  event void EnhantsPHY.phy_send_complete() {
    post task_send_done();
  }
  
  task void task_send_done() {
    //call EnhantsPHY.set_direction_recv();
    signal RadioSignal.sendDone(message_send, SUCCESS);
    uwbEnhants_state = S_STOPPING;
  }

  event void EnhantsPHY.data_arrived(msg_t *msg) {
    new_msg = msg;
    post task_data_arrived();
  }

  task void task_data_arrived() {
    uint16_t rcv_crc = 0;
    uint16_t calc_crc = 0;
    uint8_t len = 0;

    len = new_msg->len;
    len -= 2; // because we dont include the checksum

    // calc checksum
    rcv_crc = (new_msg->data[len+1] << 8) + new_msg->data[len]; 
    calc_crc = call Crc.crc16(&new_msg->data[0],len); // we skip the last 2 bytes, because they include the checksum

    // if checksum is correct we signal
    if(rcv_crc == calc_crc)
    {
      signal RadioSignal.receive(new_msg,(uint8_t*)&new_msg->data, len);
    }
    else
    {
			call PinF1.toggle();
      signal Module.drop_message(new_msg);
      return;
    }
  }
}
