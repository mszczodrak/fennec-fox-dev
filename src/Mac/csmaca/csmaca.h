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
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#ifndef _H_CSMACA_MAC_H_
#define _H_CSMACA_MAC_H_

/**
 * Ideally, your receive history size should be equal to the number of
 * RF neighbors your node will have
 */
#define CSMACA_MAC_RECEIVE_HISTORY_SIZE	4
#define CSMACA_MAC_INVALID_ELEMENT	0xFF
#define CSMACA_MAC_RECEIVE_QUEUE_SIZE	5

typedef nx_struct csmaca_header_t {
	nxle_uint16_t fcf;
	nxle_uint8_t dsn;
	nxle_uint16_t destpan;
	nxle_uint16_t dest;
	nxle_uint16_t src;
	/** CC2420 802.15.4 header ends here */
	/** I-Frame 6LowPAN interoperability byte */
	nxle_uint8_t network;
	nxle_uint8_t type;
} csmaca_header_t;

enum
{
	TIME_ACK_TURNAROUND = 7, // jiffies
};


#endif

