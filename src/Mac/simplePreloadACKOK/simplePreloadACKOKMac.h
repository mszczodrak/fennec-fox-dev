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
 * Application: implementation of simple MAC protocol
 *              MAC sends, ACKs, and preloads next message to radio buffer
 * Author: Marcin Szczodrak
 * Date: 8/24/2010
 */

#ifndef __SIMPLEPRELOADACKOK_MAC_H__
#define __SIMPLEPRELOADACKOK_MAC_H__

typedef nx_struct simplePreloadAckOk_mac_header_t {
  nxle_uint8_t length;
  nxle_uint8_t conf;
  nxle_uint16_t dest;
  nxle_uint16_t src;
} simplePreloadAckOk_mac_header_t;

enum {
  // size of the header not including the length byte
  SIMPLEPRELOADACKOK_MAC_HEADER_SIZE = sizeof( simplePreloadAckOk_mac_header_t ),
  // size of the footer (FCS field)
  SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE = sizeof( uint16_t ),

  SIMPLEPRELOADACKOK_ACK_TIME = 100,
  SIMPLEPRELOADACKOK_OK_TIME = 20,
};

typedef nx_struct simplePreloadAckOk_mac_footer_t {
  nx_uint16_t footer;
} simplePreloadAckOk_mac_footer_t;

enum {
  READY = 1,
  FIRST_LOADING = 2,
  FIRST_SENDING = 3,
  FIRST_RESENDING = 11,
  SEND_DONE = 4,
  WAITING_ACK = 5,
  RESENDING_LAST = 8,
  STOPPED = 9,
  OK_LOADING = 12,
  OK_LOADED = 13,
  OK_SENDING = 14,
  WAITING_OK = 15,
  RECEIVED_ACK = 16,
  ACK_LOADING = 17,
  ACK_LOADED = 18,
};

#endif
