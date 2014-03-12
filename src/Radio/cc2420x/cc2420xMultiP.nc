/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox cc2420x radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */

module cc2420xMultiP {
provides interface RadioReceive[uint8_t process_id];
uses interface RadioReceive as SubRadioReceive;
}

implementation {

async event bool SubRadioReceive.header(message_t* msg) {
	cc2420x_hdr_t* header = (cc2420x_hdr_t*)(msg->data);
	msg->conf = header->destpan;
	return signal RadioReceive.header[msg->conf](msg);
}

async event message_t *SubRadioReceive.receive(message_t* msg) {
	cc2420x_hdr_t* header = (cc2420x_hdr_t*)(msg->data);
	msg->conf = header->destpan;
	return signal RadioReceive.receive[msg->conf](msg);
}

default async event bool RadioReceive.header[uint8_t process_id](message_t* msg) {
	return FALSE;
}

default async event message_t * RadioReceive.receive[uint8_t process_id](message_t* msg) {
	return msg;
}


}
