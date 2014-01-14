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
  * Fennec Fox rf230 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/06/2014
  */

#ifndef __H_rf230_RADIO__
#define __H_rf230_RADIO___

typedef nx_uint32_t timesync_radio_t;

nx_struct rf230_radio_header_t {
        nxle_uint8_t length;
};

enum {
        RF230_MIN_MESSAGE_SIZE         = 5,
        RF230_MAX_MESSAGE_SIZE         = 128,
        RF230_MAX_FAILED_LOADS         = 3,
        RF230_FOOTER                   = 2,
        RF230_SIZEOF_CRC               = 2,
};

typedef nx_struct rf230_hdr_t {
        nxle_uint8_t length;
        nxle_uint16_t fcf;
        nxle_uint8_t dsn;
        nxle_uint16_t destpan;
        nxle_uint16_t dest;
        nxle_uint16_t src;
} rf230_hdr_t;


#endif
