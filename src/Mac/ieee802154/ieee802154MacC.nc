/*
 *  IEEE 802.15.4 MAC protocol for Fennec Fox platform.
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
 * MAC: implementation of IEEE 802.15.4 MAC protocol
 * Author: Marcin Szczodrak
 * Date: 8/10/2011
 * Last Modified: 8/10/2011
 */


generic configuration ieee802154MacC(bool use_cca, bool use_ack, bool use_dest_check,
                                uint8_t max_cca_retries,
                                uint8_t max_send_retries, 
                                uint16_t ack_wait_time,
                                uint16_t initial_backoff,
                                uint16_t congestion_backoff,
                                uint16_t minimum_backoff) {

  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {
  components new ieee802154MacP(use_cca, use_ack, use_dest_check, max_cca_retries, 
					max_send_retries, ack_wait_time,
			initial_backoff, congestion_backoff, minimum_backoff);
  Mgmt = ieee802154MacP;
  Module = ieee802154MacP;
  MacCall = ieee802154MacP;
  MacSignal = ieee802154MacP;
  RadioCall = ieee802154MacP;
  RadioSignal = ieee802154MacP;

  components AddressingC;
  ieee802154MacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];

  components new TimerMilliC() as BackoffTimer;
  ieee802154MacP.BackoffTimer -> BackoffTimer;

  components RandomC;
  ieee802154MacP.Random -> RandomC;
}

