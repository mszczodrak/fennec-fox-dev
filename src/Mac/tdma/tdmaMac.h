/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox TDMA MAC protocol
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/12/2012
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


enum {
  MAX_ENTRIES           = 8,              // number of entries in the table
//  BEACON_RATE           = 2,  		  // how often send the beacon msg (in seconds)
//  ROOT_BEACON_RATE      = 1,  		  // how often send the beacon msg (in seconds) at root
  ROOT_TIMEOUT          = 5,              //time to declare itself the root if no msg was received (in sync periods)
  IGNORE_ROOT_MSG       = 4,              // after becoming the root ignore other roots messages (in send period)
  ENTRY_VALID_LIMIT     = 4,              // number of entries to become synchronized
  ENTRY_SEND_LIMIT      = 3,              // number of entries to send sync messages
  ENTRY_THROWOUT_LIMIT  = 500,            // if time sync error is bigger than this clear the table
  TDMA_MIN_MULT		= 2,
  MGMT_MIN_ENTRIES	= MAX_ENTRIES - 1,
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

