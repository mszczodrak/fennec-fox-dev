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
  * Fennec Fox Data Synchronizarion Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include "hashing.h"

generic module DataSynchronizationP(process_t process) @safe() {
provides interface SplitControl;

uses interface Param;
uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

uses interface FennecData;
uses interface Random;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint16_t send_delay;
message_t packet;
uint8_t dump_offset = UNKNOWN;
uint16_t global_data_len = 0;

task void schedule_send() {
	call Param.get(SEND_DELAY, &send_delay, sizeof(send_delay));
	call Timer.startOneShot(send_delay / 2 + (call Random.rand16() % send_delay) + 1);
}

task void send_msg() {
	nx_struct fennec_network_data *data_msg;
	dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg()", process);

	data_msg = (nx_struct fennec_network_data*) 
	call SubAMSend.getPayload(&packet, sizeof(nx_struct fennec_network_data));
   
	if (data_msg == NULL) {
		printf("NULL ptr\n");
		signal SubAMSend.sendDone(&packet, FAIL);
		return;
	}

	data_msg->sequence = (nx_uint16_t) call FennecData.getDataSeq();
	data_msg->dump_offset = dump_offset;
	data_msg->crc = (nx_uint16_t) call FennecData.getDataCrc();

	if (( dump_offset == UNKNOWN ) || ( dump_offset == global_data_len )) {
		/* regular resend or end of dump */
		data_msg->data_len = call FennecData.fillNxDataUpdate(&(data_msg->data), DATA_SYNC_MAX_PAYLOAD);
		memcpy(data_msg->history, call FennecData.getHistory(), VARIABLE_HISTORY);
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		//printf("sending len %d\n", data_msg->data_len);
#endif
	} else {
		/* dump all the data
		 * the whole cache is broken down into chunks of size
		 * no more than DATA_DUMP_MAX_PAYLOAD
		 */
		uint8_t *all_data = (uint8_t*) call FennecData.getNxDataPtr();
		global_data_len = call FennecData.getNxDataLen();
		if (global_data_len > (dump_offset + DATA_DUMP_MAX_PAYLOAD)) {
			data_msg->data_len = DATA_DUMP_MAX_PAYLOAD;
		} else {
			data_msg->data_len = global_data_len - dump_offset;
		}
		
		memcpy(data_msg->data, all_data + dump_offset, data_msg->data_len);
	}

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(nx_struct fennec_network_data)) != SUCCESS) {
		dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg() - FAIL", process);
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg() - SUCCESS", process);
		printf("Send DataSync\n");
	}
}

event void FennecData.resend(bool immediate) {
	printf("FennecData.resend(%d)\n", immediate);
	if (immediate) {
		call Timer.stop();
		post send_msg();
	} else {
		post schedule_send();
	}
}

event void FennecData.dump() {
	dump_offset = 0;
	post schedule_send();
}

command error_t SplitControl.start() {
	dbg("DataSynchronization", "[%d] DataSynchronizationP SplitControl.start()", process);
	post schedule_send();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("DataSynchronization", "[%d] DataSynchronizationP SplitControl.stop()", process);
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_data *data_msg = (nx_struct fennec_network_data*) payload;
	dbg("DataSynchronization", "[%d] DataSynchronizationP SubReceive.receive(0x%1x, 0x%1x, %d)",
		process, msg, payload, len);

	call Timer.stop();

	if (data_msg->dump_offset != UNKNOWN) {
		/* this is dump message */
		if (call FennecData.getDataSeq() == 0) {
			/* we are synchronizing with the cache dump */

			if ( data_msg->dump_offset < global_data_len ) {
				uint8_t *all_data = (uint8_t*) call FennecData.getNxDataPtr();
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
				printf("Keep syncing dump (offset %d, len %d)\n",
					data_msg->dump_offset, data_msg->data_len);
#endif
				memcpy(all_data + data_msg->dump_offset, data_msg->data, data_msg->data_len);
				return msg;
			}
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("end of syncing, update history and that's it\n");
#endif
		} else {
			return msg;
		}
	}

	 printf("Receive len: %d    crc: %u    seq: %d   from: %u\n", data_msg->data_len, data_msg->crc, 
			data_msg->sequence, call SubAMPacket.source(msg));

	call FennecData.updateData(data_msg->data, data_msg->data_len, data_msg->crc,
				data_msg->history, data_msg->sequence);
	return msg;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	nx_struct fennec_network_data *data_msg = (nx_struct fennec_network_data*)
	call SubAMSend.getPayload(&packet, sizeof(nx_struct fennec_network_data));

	/* check if the sent message was part of the dump process */
	if (data_msg->dump_offset != UNKNOWN) {
		global_data_len = call FennecData.getNxDataLen();
		if (dump_offset >= global_data_len) {
			dump_offset = UNKNOWN;
		} else {
			dump_offset += DATA_DUMP_MAX_PAYLOAD;
			/* continue to dumping cache */
			printf("continue dumping...\n");
			post send_msg();
		}
	}
}

event void Timer.fired() {
	post send_msg();
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	//nx_struct fennec_network_data *data_msg = (nx_struct fennec_network_data*) payload;
	//call FennecData.setDataAndSeq(&(data_msg->data), data_msg->history, data_msg->sequence);
	return msg;
}

event void Param.updated(uint8_t var_id) {
}

}
