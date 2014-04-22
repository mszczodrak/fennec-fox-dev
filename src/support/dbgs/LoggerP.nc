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
  * Fennec Fox Logger Support
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#define MAX_NUM_LOGS 20

module LoggerP {
#ifdef FENNEC_LOGGER
provides interface Logger;
uses interface Alarm<T32khz,uint32_t> as Timer;
#endif
}

implementation {

#ifdef FENNEC_LOGGER

uint16_t log_count = 0;

typedef struct log_msg {
	uint32_t time;
	uint16_t from;
	uint16_t msg;
} log_msg_t;

log_msg_t logs[MAX_NUM_LOGS];
#endif

void insertLog(uint16_t from, uint16_t message) @C() {
#ifdef FENNEC_LOGGER
	call Logger.insert(from, message);
#endif
}

void cleanLog() @C() {
#ifdef FENNEC_LOGGER
	call Logger.clean();
#endif
}

void printLog() @C() {
#ifdef FENNEC_LOGGER
	call Logger.print();
#endif
}


#ifdef FENNEC_LOGGER
command void Logger.insert(uint16_t from, uint16_t message) {
	logs[log_count].time = call Timer.getNow();
	logs[log_count].from = from;
	logs[log_count].msg = message;
	log_count++;
}

command void Logger.clean() {
	for (log_count = 0; log_count < MAX_NUM_LOGS; log_count++) {
		memset(logs + log_count, 0, sizeof(log_msg_t));
	}
	log_count = 0;
}

command void Logger.print() {
	uint16_t i;
	for (i = 0; i < log_count; i++) {
		printf("%lu %d %d\n", logs[i].time, logs[i].from, logs[i].msg);
	}
	printf("\n");
	printfflush();
	call Logger.clean();
}

async event void Timer.fired() {
}
#endif

}
