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
  * Fennec Fox Neighbors Application module
  *
  * @author: Marcin K Szczodrak
  * @updated: 05/22/2011
  */


#include <Fennec.h>
#include "Neighbors.h"

generic module NeighborsP(process_t process) {
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

uses interface Leds;
uses interface Random;
uses interface Timer<TMilli> as SendTimer;

uses interface LocalTime<TMilli> as LocalTime;

uses interface SerialDbgs;
}

implementation {

message_t packet;

bool busy;
uint16_t seqno;

uint8_t neighborhood_min_size;
uint8_t neighbors_neighborhood_min_size;
uint8_t max_num_of_poor_neighbors;
uint8_t good_etx;
uint8_t radio_tx_power;
uint8_t num_to_check = 100;
uint16_t tx_delay;

#define NUM_RADIO_POWERS 8

uint8_t neighborhoodCounter;
uint8_t good_quality_neighbors;

uint8_t radio_powers[NUM_RADIO_POWERS] = {31, 27, 23, 19, 15, 11, 7, 3};

NeighborsData my_data[NEIGHBORHOOD_DATA];

message_metadata_t* getMetadata(message_t *msg) {
	return (message_metadata_t*)msg->metadata;
}

task void send_timer() {
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call SendTimer.startOneShot( (call Random.rand16() % tx_delay) + 
			(tx_delay / 2) + 1);
}

void clean_record(uint8_t i) {
	my_data[i].node = BROADCAST;
	my_data[i].first_seq = 0;
	my_data[i].last_seq = 0;
	my_data[i].timestamp = 0;
	my_data[i].rec = 0;
	my_data[i].radio_tx = 0;
	my_data[i].size = 0;
	my_data[i].etx = 0;
}

void start_new_radio_tx_test() {
	uint8_t i;

	busy = FALSE;
	neighborhoodCounter = 0;
	good_quality_neighbors = 0;
	seqno = 0;

	for ( i = 0 ; i < NEIGHBORHOOD_DATA; i++ ) {
		clean_record(i);
	}

	post send_timer();
}

void updateNeighborhoodCounter() {
	uint8_t i;
	uint8_t neighbors_in_need = 0;
	uint8_t dont_hear_us = 0;
	good_quality_neighbors = 0;
	neighborhoodCounter = 0;

	for ( i = 0 ; i < NEIGHBORHOOD_DATA; i++ ) {
		if ( my_data[i].node == BROADCAST ) {
			continue;
		}

		if ( my_data[i].rec > 0 ) {
			neighborhoodCounter++;

			if ( my_data[i].size < neighbors_neighborhood_min_size ) {
				neighbors_in_need++;
			}

			if ( my_data[i].etx > good_etx ) {
				good_quality_neighbors++;
			}
		} else {
			dont_hear_us++;
		}
	}

#ifdef __DBGS__APPLICATION__
        call SerialDbgs.dbgs(DBGS_STATUS_UPDATE, neighborhoodCounter, good_quality_neighbors, neighbors_in_need);
#endif

	if (seqno < num_to_check) {
		return;
	}

	
	if ((good_quality_neighbors > neighborhood_min_size) && (neighbors_in_need <= max_num_of_poor_neighbors)) {

		for( i = 0; i < NUM_RADIO_POWERS; i++) {
			if (radio_powers[i] < radio_tx_power) {
				radio_tx_power = radio_powers[i];
				call Param.set(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
				printf("Lower to %d  [ Neighborhood: All: %d   Good: %d   Need Help: %d  Lost: %d ]\n", 
					radio_tx_power, neighborhoodCounter, good_quality_neighbors,
					neighbors_in_need, dont_hear_us);
#endif
	
#ifdef __DBGS__APPLICATION__
				call SerialDbgs.dbgs(DBGS_CHANNEL_RESET, process, i, radio_tx_power);
#endif
				start_new_radio_tx_test();
				return;
			}
		}
	}

	if (good_quality_neighbors < neighborhood_min_size) {

		for( i = 1; i < NUM_RADIO_POWERS; i++) {
			if (radio_powers[i] == radio_tx_power) {
				radio_tx_power = radio_powers[i-1];
				call Param.set(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
				printf("Increase to %d  [ Neighborhood: All: %d   Good: %d   Need Help: %d  Lost: %d ]\n", 
					radio_tx_power, neighborhoodCounter, good_quality_neighbors,
					neighbors_in_need, dont_hear_us);
#endif
#ifdef __DBGS__APPLICATION__
				call SerialDbgs.dbgs(DBGS_CHANNEL_RESET, process, i, radio_tx_power);
#endif
				start_new_radio_tx_test();
				break;
			}
		}
	}
}

void remove_node(nx_uint16_t src) {
	uint8_t i;

	/* clean up neighbor */
	for ( i = 0 ; i < NEIGHBORHOOD_DATA; i++ ) {
		if (my_data[i].node == src) {
			clean_record(i);
			return;
		}
	}
}


void add_receive_node(nx_uint16_t src, nx_uint8_t tx, nx_uint16_t seq,
					nx_uint16_t size, uint8_t hears_us) {
	uint8_t i;
	uint32_t now_time = call LocalTime.get();

	/* check if there are any old neighbors that should be removed */
	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		if ( (my_data[i].node != BROADCAST) && ( my_data[i].timestamp + (11 * tx_delay) < now_time ) ) {
			/* we have missed the last 10 transmissions from node i */
			clean_record(i);
		}
	}


	/* find the spot of the node */
	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		if (my_data[i].node == src) {
			break;
		}
	}

	/* find new empty record */
	if ( i == NEIGHBORHOOD_DATA ) {
		uint8_t candidate = NEIGHBORHOOD_DATA - 1;
		uint32_t smallest_time = 2147483647;
		for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
			if (my_data[i].node == BROADCAST) {
				candidate = i;
				break;
			}
			if (my_data[i].timestamp < smallest_time) {
				smallest_time = my_data[i].timestamp;
				candidate = i;
			}
		}
		clean_record(i);		
		i = candidate;
	}

	if ( my_data[i].node == BROADCAST ) {
		/* first time */
		my_data[i].node = src;
		my_data[i].first_seq = seq;
	}

	if ( hears_us == FALSE) {	
		my_data[i].rec = 0;
	} else {
		my_data[i].rec++;
	}

	my_data[i].size = size;
	my_data[i].last_seq = seq;
	my_data[i].timestamp = now_time;
	my_data[i].radio_tx = tx;
	my_data[i].etx = (my_data[i].rec * 100) / (my_data[i].last_seq - my_data[i].first_seq + 1);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	//printf("Update: Node %d   NSize %d   TX %d   Rec %d   ETX %d\n",
	//		src, size, tx, my_data[i].rec, my_data[i].rec * 100 / seq);
#endif
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_GOT_RECEIVE, src, my_data[i].rec, seq);
#endif
	updateNeighborhoodCounter();
}

command error_t SplitControl.start() {

	call Param.get(NEIGHBORHOOD_MIN_SIZE, &neighborhood_min_size, sizeof(neighborhood_min_size));
	call Param.get(NEIGHBORS_NEIGHBORHOOD_MIN_SIZE, &neighbors_neighborhood_min_size, sizeof(neighbors_neighborhood_min_size));
	call Param.get(MAX_NUM_OF_POOR_NEIGHBORS, &max_num_of_poor_neighbors, sizeof(max_num_of_poor_neighbors));
	call Param.get(GOOD_ETX, &good_etx, sizeof(good_etx));
	call Param.get(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call Param.get(NUM_TO_CHECK, &num_to_check, sizeof(num_to_check));

#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
	start_new_radio_tx_test();
	
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {

	call SendTimer.stop();
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
	post send_timer();
#ifdef __DBGS__APPLICATION__
        call SerialDbgs.dbgs(DBGS_SEND_DATA, error, seqno, radio_tx_power);
#endif
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t i;
	NeighborsMsg *m = (NeighborsMsg*) payload;

	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		if (m->data[i].node == TOS_NODE_ID) {
			/* this node hears us */
			if ( m->data[i].radio_tx == radio_tx_power ) {
				/* this node hears us with the current radio control */
				add_receive_node(m->src, m->tx, m->seq, m->size, TRUE);
				return msg;
			} else {
				/* here are nodes that we lost since power upgrade */
#ifdef __DBGS__APPLICATION__
				call SerialDbgs.dbgs(DBGS_GOT_RECEIVE_STATE_FAIL, m->src, m->seq, m->data[i].radio_tx);
#endif
				/* this node does not know about us anymore */
			}
			break;
		}
	}

	/* case when a node does not hears us... */
	/* may be the case that it used to hear us, but only has older tx_power */
	/* this node does not know about us */
	add_receive_node(m->src, m->tx, m->seq, m->size, FALSE);
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	uint8_t i;
	NeighborsMsg *msg = (NeighborsMsg*) call SubAMSend.getPayload(&packet,
							sizeof(NeighborsMsg));
	if (msg == NULL || busy) {
		post send_timer();
	}

	busy = TRUE;
	call Param.get(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));
	msg->src = TOS_NODE_ID;
	msg->tx = radio_tx_power;
	msg->seq = ++seqno;
	msg->size = good_quality_neighbors;
	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		msg->data[i].node = my_data[i].node;
		msg->data[i].radio_tx = my_data[i].radio_tx;
		msg->data[i].etx = my_data[i].etx;
	}

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(NeighborsMsg)) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	}
}

event void Param.updated(uint8_t var_id) {

}

}
