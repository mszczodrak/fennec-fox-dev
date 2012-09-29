/*
 *  Dummy radio module for Fennec Fox platform.
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
 * Network: Dummy Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "cc2420Radio.h"

module cc2420RadioP @safe() {
  provides interface Mgmt;
  provides interface ModuleStatus as RadioStatus;

  uses interface cc2420RadioParams;
  uses interface RadioConfig;

  uses interface StdControl as ReceiveControl;
  uses interface StdControl as TransmitControl;

  uses interface RadioPower;
  uses interface Resource as RadioResource;

  uses interface State as RadioState;

  provides interface StdControl;
}

implementation {

  uint8_t mgmt;


  command error_t Mgmt.start() {
    mgmt = TRUE;
    call StdControl.start();
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    mgmt = TRUE;
    call StdControl.stop();
    signal Mgmt.stopDone( SUCCESS );
    return SUCCESS;
  }

  command error_t StdControl.start() {
    if (call RadioState.requestState(S_STARTING) == SUCCESS) {
      call RadioPower.startVReg();
      return SUCCESS;

    } else if(call RadioState.isState(S_STARTED)) {
      return EALREADY;

    } else if(call RadioState.isState(S_STARTING)) {
      return SUCCESS;
    }

    return EBUSY;
  }

  task void stop_done() {
    call ReceiveControl.stop();
    call TransmitControl.stop();
    call RadioPower.stopVReg();

    call RadioState.forceState(S_STOPPED);
    if (mgmt == TRUE) {
      signal Mgmt.stopDone(SUCCESS);
      mgmt = FALSE;
    }
  }


  command error_t StdControl.stop() {
    if (call RadioState.isState(S_STARTED)) {
      call RadioState.forceState(S_STOPPING);
      post stop_done();
      return SUCCESS;

    } else if(call RadioState.isState(S_STOPPED)) {
      return EALREADY;

    } else if(call RadioState.isState(S_STOPPING)) {
      return SUCCESS;
    }

    return EBUSY;
  }

  event void cc2420RadioParams.receive_status(uint16_t status_flag) {
  }


  /****************** RadioConfig Events ****************/
  event void RadioConfig.syncDone( error_t error ) {
  }

  task void resource_request() {
    call RadioResource.request();
  }

  async event void RadioPower.startVRegDone() {
    post resource_request();
  }

  task void start_done() {
    call RadioPower.rxOn();
    call RadioResource.release();

    call ReceiveControl.start();
    call TransmitControl.start();

    call RadioState.forceState(S_STARTED);

    if (mgmt == TRUE) {
      signal Mgmt.startDone(SUCCESS);
      mgmt = FALSE;
    }
  }

  async event void RadioPower.startOscillatorDone() {
    post start_done();
  }

  event void RadioResource.granted() {
    call RadioPower.startOscillator();
  }


}

