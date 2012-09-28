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

  provides interface StdControl;
}

implementation {

  command error_t Mgmt.start() {
    call StdControl.start();
    dbg("Radio", "Radio cc2420 starts\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call StdControl.stop();
    dbg("Radio", "Radio cc2420 stops\n");
    signal Mgmt.stopDone( SUCCESS );
    return SUCCESS;
  }

  command error_t StdControl.start() {
    call ReceiveControl.start();
    return call TransmitControl.start();
  }

  command error_t StdControl.stop() {
//    call RadioPower.stopVReg();
    call ReceiveControl.stop();
    return call TransmitControl.stop();
  }

  event void cc2420RadioParams.receive_status(uint16_t status_flag) {
  }


  /****************** RadioConfig Events ****************/
  event void RadioConfig.syncDone( error_t error ) {
  }

  async event void RadioPower.startVRegDone() {
//    post resource_request();
  }

  async event void RadioPower.startOscillatorDone() {
//    post startDone_task();
  }


}

