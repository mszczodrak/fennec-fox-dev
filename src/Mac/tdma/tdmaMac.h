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

#ifndef __H_TDMA_MAC_H_
#define __H_TDMA_MAC_H_

#define SYNC_PREC_TMILLI
//#define SYNC_PREC_32K

typedef nx_struct tdma_header_t {
  nxle_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
  /** CC2420 802.15.4 header ends here */
  /** I-Frame 6LowPAN interoperability byte */
  nxle_uint8_t network;
  nxle_uint8_t type;
} tdma_header_t;


#ifndef TIMESYNC_RATE
#define TIMESYNC_RATE   3
#endif

enum {
  MAX_ENTRIES           = 8,              // number of entries in the table
  BEACON_RATE           = TIMESYNC_RATE,  // how often send the beacon msg (in seconds)
  ROOT_TIMEOUT          = 5,              //time to declare itself the root if no msg was received (in sync periods)
  IGNORE_ROOT_MSG       = 4,              // after becoming the root ignore other roots messages (in send period)
  ENTRY_VALID_LIMIT     = 4,              // number of entries to become synchronized
  ENTRY_SEND_LIMIT      = 3,              // number of entries to send sync messages
  ENTRY_THROWOUT_LIMIT  = 500,            // if time sync error is bigger than this clear the table
};

typedef struct TableItem
{
  uint8_t     state;
  uint32_t    localTime;
  int32_t     timeOffset; // globalTime - localTime
} TableItem;

enum {
  ENTRY_EMPTY = 0,
  ENTRY_FULL = 1,
};

#endif

