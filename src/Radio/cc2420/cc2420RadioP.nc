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

  provides interface SplitControl;
}

implementation {

  norace uint8_t state = S_STOPPED;
  uint8_t mgmt = FALSE;

  task void start_done() {
    state = S_STARTED;
    printf("Radio task start done\n");
    printfflush();

    signal SplitControl.startDone(SUCCESS);
    if (mgmt == TRUE) {
      signal Mgmt.startDone(SUCCESS);
      mgmt = FALSE;
    }
  }

  task void finish_starting_radio() {
    call RadioPower.rxOn();
    call RadioResource.release();
    call ReceiveControl.start();
    call TransmitControl.start();
    post start_done();
  }


  task void stop_done() {
    state = S_STOPPED;
    printf("Radio task stop done\n");
    printfflush();
    signal SplitControl.stopDone(SUCCESS);
    if (mgmt == TRUE) {
      signal Mgmt.stopDone(SUCCESS);
      mgmt = FALSE;
    }
  }

  command error_t Mgmt.start() {
    printf("Radio mgmt start\n");
    mgmt = TRUE;
    call SplitControl.start();
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    printf("Radio mgmt stop\n");
    mgmt = TRUE;
    call SplitControl.stop();
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    if (state == S_STOPPED) {
      state = S_STARTING;
      printf("Radio split start 1\n");
      printfflush();
      call RadioPower.startVReg();
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

  command error_t SplitControl.stop() {
    if (state == S_STARTED) {
      state = S_STOPPING;
      call ReceiveControl.stop();
      call TransmitControl.stop();
      call RadioPower.stopVReg();
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


  async event void RadioPower.startOscillatorDone() {
    post finish_starting_radio();
  }

  event void RadioResource.granted() {
    call RadioPower.startOscillator();
  }


}

