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
  * Fennec Fox global constants
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#ifndef FF_CONSTANTS_H
#define FF_CONSTANTS_H


#define TYPE_NONE	0
#define TYPE_SECOND	1
#define TYPE_MINUTE	2
#define TYPE_HOUR	3
#define TYPE_DAY	4

#define UQ_RADIO_ALARM          "UQ_CC2420X_RADIO_ALARM"


enum {
        OFF                     = 0,
        ON                      = 1,

        UP                      = 0,
        DOWN                    = 1,

        EQ                      = 1,
        NQ                      = 2,
        LT                      = 3,
        LE                      = 4,
        GT                      = 5,
        GE                      = 6,

        CONFIGURATION_SEQ_UNKNOWN = 0,

        MESSAGE_CACHE_LEN       = 25,

	MAX_NUM_EVENTS		= 32,

	NUMBER_OF_ACCEPTING_CONFIGURATIONS = 10,
	ACCEPTING_RESEND	= 2,

        DEFAULT_FENNEC_SENSE_PERIOD = 1024,

	NODE			= 0xfffa,
        BRIDGE                  = 0xfffc,
        UNKNOWN                 = 0xfffd,
        MAX_COST                = 0xfffe,
        BROADCAST               = 0xffff,

	MAX_ADDR_LENGTH		= 8, 		/* in bytes */

	F_MINIMUM_STATE_LEVEL	= 0,


	ANY			= 253,
        UNKNOWN_CONFIGURATION   = 0xfff9,
        UNKNOWN_LAYER           = 255,
	UNKNOWN_ID		= 0xfff0,

                /* Panic Levels */
        PANIC_OK                = 0,
        PANIC_DEAD              = 1,
        PANIC_WARNING           = 2,

	F_NODE			= 20,
	F_BRIDGE		= 21,
	F_BASE_STATION		= 22,

	F_SYSTEM		= 23,
	F_MEMORY		= 24,
	F_SENSOR		= 25,

        FENNEC_SYSTEM_FLAGS_NUM = 30,
	FENNEC_MSG_DATA_LEN	= 128,
};

#endif
