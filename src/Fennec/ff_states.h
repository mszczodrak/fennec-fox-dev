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
  * Fennec Fox global states
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#ifndef FF_STATES_H
#define FF_STATES_H

typedef enum {
        /* States */
        S_NONE                  = 0,
        S_STOPPED               = 1,
        S_STARTING              = 2,
        S_STARTED               = 3,
        S_STOPPING              = 4,
        S_TRANSMITTING          = 5,
        S_LOADING               = 6,
        S_LOADED                = 7,
        S_CANCEL                = 8,
        S_ACK_WAIT              = 9,
        S_SAMPLE_CCA            = 10,
        S_SENDING_ACK           = 11,
        S_NOT_ACKED             = 12,
        S_BROADCASTING          = 13,
        S_HALTED                = 14,
        S_BRIDGE_DELAY          = 15,
        S_DISCOVER_DELAY        = 16,
        S_INIT                  = 17,
        S_SYNC                  = 18,
        S_SYNC_SEND             = 19,
        S_SYNC_RECEIVE          = 20,
        S_SEND_DONE             = 21,
        S_SLEEPING              = 22,
        S_OPERATIONAL           = 23,
        S_TURN_ON               = 24,
        S_TURN_OFF              = 25,
        S_PREAMBLE              = 26,
        S_RECEIVING             = 27,
	S_BEGIN_TRANSMIT        = 28,
	S_LOAD                  = 29,
	S_RECONFIGURING		= 30,
	S_RECONF_ENABLED	= 31,
        S_COMPLETED		= 32,
	S_BUSY			= 33,
	S_SERIAL		= 34,
	S_NEW_STATE		= 35,
	S_RESET			= 36,
	S_ERROR			= 37,


                /* tx */
        S_SFD                   = 40,
        S_EFD                   = 41,

                /* rx */
        S_RX_LENGTH             = 42,
        S_RX_FCF                = 43,
        S_RX_PAYLOAD            = 44,
} fennec_state_t;


#endif
