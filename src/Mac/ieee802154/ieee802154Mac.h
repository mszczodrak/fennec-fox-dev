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


#ifndef __IEEE802154_MAC_H__
#define __IEEE802154_MAC_H__

#include "Ieee154.h"

/*
  SimpleAddr Mac header
  
  +----------------+--------------------+---------------+
  |  fennec_header |  destination_addr  |  source_addr  |
  +----------------+--------------------+---------------+

*/

//  IEEE802154_BACKOFF_PERIOD = 5, /* Table 86 */
//  IEEE802154_INITIAL_BACKOFF_PERIOD = 20, 
//  IEEE802154_CONGESTION_BACKOFF_PERIOD = 10, 
//  IEEE802154_MIN_BACKOFF = 3, /* Tbale 86 */
//  IEEE802154_TIME_ACK_TURNAROUND = 40, /* 6.4.1 */
//  IEEE802154_MAC_CSMA_BACKOFFS = 4, /* 7.4.2 */

nx_struct ieee802154_mac_header {
  /* nx_struct fennec_header fennec; */
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  /* nx_uint16_t dest; */
  /* nx_uint16_t src; */
};

nx_struct ieee802154ack_mac_header {
  /* nxle_uint16_t length; */
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
};

nx_struct ieee802154_mac_footer {
  nx_uint16_t footer;
};

#endif
