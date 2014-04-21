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
  * Fennec Fox Dbg flags
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#ifndef __DBGS_H_
#define __DBGS_H_


#define DBGS_SEND_DATA		1
#define DBGS_SEND_BEACON	2
#define DBGS_RECEIVE_DATA 	3
#define DBGS_RECEIVE_BEACON  	4

#define DBGS_MGMT_START		5
#define DBGS_MGMT_STOP		6

#define DBGS_MEMORY_EMPTY	7
#define DBGS_BLINK_LED		8
#define DBGS_SYNC		10

#define DBGS_GOT_SEND				20
#define DBGS_GOT_SEND_HEADER_NULL_FAIL		21
#define DBGS_GOT_SEND_STATE_FAIL		22
#define DBGS_GOT_SEND_FULL_QUEUE_FAIL		23
#define DBGS_GOT_SEND_EMPTY_QUEUE_FAIL		24
#define DBGS_GOT_SEND_FURTHER_SEND_FAIL		25
#define DBGS_FORWARDING				26

#define DBGS_GOT_RECEIVE			30
#define DBGS_GOT_RECEIVE_HEADER_NULL_FAIL	31
#define DBGS_GOT_RECEIVE_STATE_FAIL		32
#define DBGS_GOT_RECEIVE_FULL_QUEUE_FAIL	33
#define DBGS_GOT_RECEIVE_EMPTY_QUEUE_FAIL	34
#define DBGS_GOT_RECEIVE_FURTHER_SEND_FAIL	35
#define DBGS_GOT_RECEIVE_FORWARDING		36
#define DBGS_GOT_RECEIVE_TYPE_FAIL		37
#define DBGS_GOT_RECEIVE_DUPLICATE		38

#define DBGS_NEW_CHANNEL			40
#define DBGS_CHANNEL_RESET			41
#define DBGS_SYNC_PARAMS			42
#define DBGS_CHANNEL_TIMEOUT_NEXT		43
#define DBGS_CHANNEL_TIMEOUT_RESET		44
#define DBGS_SYNC_PARAMS_FAIL			45
#define DBGS_RADIO_START_V_REG			46
#define DBGS_RADIO_STOP_V_REG			47
#define DBGS_RADIO_ON_PERIOD			48

#define DBGS_NOT_ACKED_RESEND			50
#define DBGS_NOT_ACKED_FAILED			51
#define DBGS_NOT_ACKED				52
#define DBGS_ACKED				53

#define DBGS_SEND_CONTROL_MSG			101
#define DBGS_RECEIVE_CONTROL_MSG		102
#define DBGS_RECEIVE_FIRST_CONTROL_MSG		103
#define DBGS_RECEIVE_UNKNOWN_CONTROL_MSG	104
#define DBGS_RECEIVE_LOWER_CONTROL_MSG		105
#define DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG	106
#define DBGS_RECEIVE_HIGHER_CONTROL_MSG		107
#define DBGS_RECEIVE_WRONG_CONF_MSG		108
#define DBGS_RECEIVE_AND_RECONFIGURE		109
#define DBGS_SEND_CONTROL_MSG_FAILED		110

#define DBGS_ERROR				130
#define DBGS_ERROR_SEND_DONE			131
#define DBGS_ERROR_RECEIVE			132

#define DBGS_TIMER_FIRED			160
#define DBGS_BUSY				161

#define DBGS_TEST_SIGNAL	32767

#endif
