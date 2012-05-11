/*
 * Copyright (c) 2011 Columbia University.
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
 * Application: implementation of simple MAC protocol, just sends with addressing
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#ifndef __SIMPLEACK_MAC_H__
#define __SIMPLEACK_MAC_H__


/*
  SimpleAddr Mac header
  
  +----------------+--------------------+---------------+
  |  fennec_header |  destination_addr  |  source_addr  |
  +----------------+--------------------+---------------+

*/

enum {
  SIMPLEACK_DATA_TO_ACK_FLAG 		= 2,
  SIMPLEACK_DATA_NO_ACK_FLAG 		= 4,
  SIMPLEACK_ACK_BACK_FLAG 		= 8,

  SIMPLEACK_QUEUE_LEN			= 4,

  SIMPLEACK_MAX_SEQUENCE		= 200,
  SIMPLEACK_ACK_WAIT_TIME		= 100,
};

nx_struct simpleACK_mac_header {
  nx_uint8_t len;
  nx_uint8_t flag;
  nx_uint8_t seq;
  /* nx_struct fennec_header fennec; */
  /* nx_uint16_t dest; */
  /* nx_uint16_t src; */
};

nx_struct simpleACK_mac_footer {
  nx_uint16_t footer;
};

struct qe_msg {
  msg_t* msg;
  nx_uint8_t seq;
  uint16_t timeup;
};

#endif
