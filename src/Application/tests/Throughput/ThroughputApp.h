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
  * Throughput Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#ifndef __THROUGHPUT_APP_H_
#define __THROUGHPUT_APP_H_

#define APP_MAX_NUMBER_OF_SENSORS	3
#define APP_NETWORK_QUEUE_SIZE 		APP_MAX_NUMBER_OF_SENSORS + 2
#if !defined(__DBGS__) && !defined(FENNEC_TOS_PRINTF)
#define APP_SERIAL_QUEUE_SIZE 		APP_MAX_NUMBER_OF_SENSORS + 2
#else
#define APP_SERIAL_QUEUE_SIZE 		0
#endif
#define APP_MESSAGE_POOL 		APP_NETWORK_QUEUE_SIZE + APP_SERIAL_QUEUE_SIZE + 4

/* this is the application structure that we send across the network */
typedef nx_struct app_data_t {
  nx_uint16_t src;    		/* address of the node sending sensor samples */
  nx_uint32_t seqno;		/* message sequence number */
  nx_uint32_t freq;		/* sampling frequency (ms) */
  nx_uint16_t (COUNT(0) data)[0]; /* place-holder for data */
} app_data_t;


typedef struct msg_queue_t {
  uint8_t len;
  uint16_t addr;
  message_t *msg;
} msg_queue_t;


typedef struct app_network_internal_t {
  uint8_t sample_count;
  uint8_t seqno;
  uint32_t freq;
  app_data_t *pkt;
  uint8_t len;
  message_t *msg;
} app_network_internal_t;

#endif
