/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/** 
 * This layer keeps a history of the past RECEIVE_HISTORY_SIZE received messages
 * If the source address and dsn number of a newly received message matches
 * our recent history, we drop the message because we've already seen it.
 * @author David Moss
 */

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
  * CSMA MAC adaptation based on the TinyOS ActiveMessage stack for CC2420.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

 
#include "csmacaMac.h"

module UniqueReceiveP @safe() {
provides interface Send;
provides interface Receive;
provides interface Init;
  
uses interface RadioReceive as SubReceive;
uses interface Send as SubSend;
uses interface RadioPacket;
uses interface Random;
}

implementation {
 
uint8_t localSendId = 0;
 
struct {
	uint16_t source;
	uint8_t dsn;
} receivedMessages[RECEIVE_HISTORY_SIZE];
  
uint8_t writeIndex = 0;
  
/** History element containing info on a source previously received from */
uint8_t recycleSourceElement;
  
enum {
	INVALID_ELEMENT = 0xFF,
	RECEIVE_QUEUE_SIZE = 5,
};


message_t receiveQueueData[RECEIVE_QUEUE_SIZE];
message_t* receiveQueue[RECEIVE_QUEUE_SIZE];

uint8_t receiveQueueHead;
uint8_t receiveQueueSize;



/***************** Init Commands *****************/
command error_t Init.init() {
	int i;
	for(i = 0; i < RECEIVE_HISTORY_SIZE; i++) {
		receivedMessages[i].source = (am_addr_t) 0xFFFF;
		receivedMessages[i].dsn = 0;
	}

	for(i = 0; i < RECEIVE_QUEUE_SIZE; ++i) {
		receiveQueue[i] = receiveQueueData + i;
	}

	localSendId = call Random.rand16();

	return SUCCESS;
}
  
/***************** Prototypes Commands ***************/
bool hasSeen(uint16_t msgSource, uint8_t msgDsn);
void insert(uint16_t msgSource, uint8_t msgDsn);
uint16_t getSourceKey(message_t ONE *msg);

task void deliverTask() {
	// get rid of as many messages as possible without interveining tasks
	message_t* msg;
	uint16_t msgSource;
	uint8_t *p;
	csmaca_header_t* header;
	uint8_t msgDsn;

	atomic {
               	if( receiveQueueSize == 0 ) {
                       	return;
		}

		msg = receiveQueue[receiveQueueHead];
		msgSource = getSourceKey(msg);
		p = (uint8_t*)(msg->data);
		header = (csmaca_header_t*) (p + call RadioPacket.headerLength(msg));
		msgDsn = header->dsn;
	}

	if(!hasSeen(msgSource, msgDsn)) {
		insert(msgSource, msgDsn);
		//dbgs(F_MAC, S_RECEIVING, DBGS_RECEIVE_DATA, header->src, header->dest);
		msg = signal Receive.receive(msg, (void*)header, call RadioPacket.payloadLength(msg));
	}

	//call RadioPacket.clear(msg);
                        
	atomic {
		receiveQueue[receiveQueueHead] = msg;
		if( ++receiveQueueHead >= RECEIVE_QUEUE_SIZE )
			receiveQueueHead = 0;

		--receiveQueueSize;
	}

	post deliverTask();
}

command error_t Send.send(message_t *msg, uint8_t len) {
	csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(msg, len);
	header->dsn = localSendId;
	localSendId = (localSendId + 1) % INVALID_ELEMENT;
	return call SubSend.send(msg, len);
}

command error_t Send.cancel(message_t *msg) {
        return call SubSend.cancel(msg);
}


command uint8_t Send.maxPayloadLength() {
        return call SubSend.maxPayloadLength();
}

command void *Send.getPayload(message_t* msg, uint8_t len) {
        return call SubSend.getPayload(msg, len);
}

/***************** SubSend Events ****************/
event void SubSend.sendDone(message_t *msg, error_t error) {
        //csmaca_header_t* header = (csmaca_header_t*)call SubSend.getPayload(msg, sizeof(csmaca_header_t));
        //dbgs(F_MAC, S_NONE, DBGS_SEND_DATA, header->src, header->dest);
        signal Send.sendDone(msg, error);
}




  
/***************** SubReceive Events *****************/
async event message_t *SubReceive.receive(message_t* msg) {
	message_t *m;
	atomic {
		if( receiveQueueSize >= RECEIVE_QUEUE_SIZE ) {
			m = msg;
		} else {
			uint8_t idx = receiveQueueHead + receiveQueueSize;
			if( idx >= RECEIVE_QUEUE_SIZE )
				idx -= RECEIVE_QUEUE_SIZE;

			m = receiveQueue[idx];
			receiveQueue[idx] = msg;

			++receiveQueueSize;
			post deliverTask();
		}
	}
	return m;
}
  
async event bool SubReceive.header(message_t* msg) {
	if (receiveQueueSize < RECEIVE_QUEUE_SIZE) {
		uint8_t *p = (uint8_t*)(msg->data);
		csmaca_header_t* header = (csmaca_header_t*) (p + call RadioPacket.headerLength(msg));
	        return ((header->dest == TOS_NODE_ID) || (header->dest == AM_BROADCAST_ADDR));
	} else {
		return FALSE;
	}
	//return TRUE;
}


/****************** Functions ****************/  
/**
 * This function does two things:
 *  1. It loops through our entire receive history and detects if we've 
 *     seen this DSN before from the given source (duplicate packet)
 *  2. It detects if we've seen messages from this source before, so we know
 *     where to update our history if it turns out this is a new message.
 *
 * The global recycleSourceElement variable stores the location of the next insert
 * if we've received a packet from that source before.  Otherwise, it's up 
 * to the insert() function to decide who to kick out of our history.
 */
bool hasSeen(uint16_t msgSource, uint8_t msgDsn) {
	int i;
	recycleSourceElement = INVALID_ELEMENT;

	atomic {
		for(i = 0; i < RECEIVE_HISTORY_SIZE; i++) {
			if(receivedMessages[i].source == msgSource) {
				if(receivedMessages[i].dsn == msgDsn) {
					// Only exit this loop if we found a duplicate packet
					return TRUE;
				}
				recycleSourceElement = i;
			}
		}
	}
	return FALSE;
}
  
/**
 * Insert the message into the history.  If we received a message from this
 * source before, insert it into the same location as last time and verify
 * that the "writeIndex" is not pointing to that location. Otherwise,
 * insert it into the "writeIndex" location.
 */
void insert(uint16_t msgSource, uint8_t msgDsn) {
	uint8_t element = recycleSourceElement;
	bool increment = FALSE;
   
	atomic {
		if(element == INVALID_ELEMENT || writeIndex == element) {
			// Use the writeIndex element to insert this new message into
			element = writeIndex;
			increment = TRUE;
		}
		receivedMessages[element].source = msgSource;
		receivedMessages[element].dsn = msgDsn;
		if(increment) {
			writeIndex++;
			writeIndex %= RECEIVE_HISTORY_SIZE;
		}
	}
}

/**
 * Derive a key to to store the source address with.
 *
 * For long (EUI64) addresses, use the sum of the word in the
 * address as a key in the table to avoid manipulating the full
 * address.
 */
uint16_t getSourceKey(message_t * ONE msg) {
	uint8_t *p = (uint8_t*)(msg->data);
	csmaca_header_t* hdr = (csmaca_header_t*) (p + call RadioPacket.headerLength(msg)); 

	int s_mode = (hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3;
	int d_mode = (hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3;
	int s_offset = 2, s_len = 2;
	uint16_t key = 0;
	uint8_t *current = (uint8_t *)&hdr->dest;
	int i;

	if (s_mode == IEEE154_ADDR_EXT) {
		s_len = 8;
	}
	if (d_mode == IEEE154_ADDR_EXT) {
		s_offset = 8;
	}

	current += s_offset;
    
	for (i = 0; i < s_len; i++) {
		key += current[i];
	}
	return key;
}

}

