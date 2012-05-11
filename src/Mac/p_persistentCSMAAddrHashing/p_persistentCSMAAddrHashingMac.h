/*
 * Copyright (c) 2010 Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Application: implementation of p-persistant CSMA
 * Author: Marcin Szczodrak
 * Date: 8/28/2010
 */

#ifndef __PPERSISTENTCSMAADDRHASHING_MAC_H__
#define __PPERSISTENTCSMAADDRHASHING_MAC_H__

/*
  p-persistentCSMA Mac header
  
  +----------------+------+--------+-------------------+---------------+
  |  fennec_header | len  |  hash  | destination_addr  |  source_addr  |
  +----------------+------+--------+-------------------+---------------+

*/

nx_struct p_persistentCSMAAddrHashing_mac_header {
  /* nx_struct fennec_header fennec; */
  nx_uint8_t len;
  nx_uint8_t hash;
  /* dest; */
  /* src; */
};

nx_struct p_persistentCSMAAddrHashing_mac_footer {
  nx_uint16_t footer;
};

enum {
  PPERSISTENTCSMAADDRHASHING_ACK_TIME = 200,

  PPERSISTENTCSMAADDRHASHING_SAMPLE_DELAY = 1,

  PPERSISTENTCSMAADDRHASHING_SEND_ATTEMPTS = 3,

  PPERSISTENTCSMAADDRHASHING_P_VALUE = 1,  // This is 1 -> 0.01 and 100 for 1,   p/100
};


#endif
