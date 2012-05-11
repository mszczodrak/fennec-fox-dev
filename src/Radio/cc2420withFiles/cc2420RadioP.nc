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

generic module cc2420RadioP() @safe() {
  provides interface Mgmt;
  provides interface Module;

  uses interface SplitControl as RadioControl;
  uses interface LowPowerListening;
}

implementation {

  command error_t Mgmt.start() {
    if (call RadioControl.start() != SUCCESS) {
      signal Mgmt.startDone(SUCCESS);
    }
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    if (call RadioControl.stop() != SUCCESS) {
      signal Mgmt.stopDone( SUCCESS );
    }
    return SUCCESS;
  }


  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    } else {
      signal Mgmt.startDone(SUCCESS);
    }
  }


  event void RadioControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.stop();
    } else {
      signal Mgmt.stopDone(SUCCESS);
    }
  }


}

