/*
 *  GOALI-Centralized application for Fennec Fox platform.
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
 * Application: GOALI project centralized application
 * Author: Marcin Szczodrak
 * Date: 8/15/2011
 * Last Modified: 8/15/2011
 */

#include <Fennec.h>

module GOALIDistributedAppP {
  provides interface GOALIBuffer;

  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint32_t mu;

  command void GOALIBuffer.put_mu(uint32_t new_mu) {
    mu = new_mu;
  }

  command uint32_t GOALIBuffer.get_mu() {
    return mu;
  }
 








  command error_t Mgmt.start() {
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    return SUCCESS;
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {}

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {}
}
