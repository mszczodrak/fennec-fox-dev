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
  * Fennec Fox NeighborsRssi Application module
  *
  * @author: Marcin K Szczodrak
  * @updated: 05/22/2011
  */


#include <Fennec.h>
#include "NeighborsRssi.h"

generic module NeighborsRssiP(process_t process) {
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
uint8_t max_num_of_poor_neighbors;
int8_t good_rssi;
float rssi_scale;
int8_t rssi_offset;
uint8_t tx_power;
uint8_t num_to_check = 100;
uint16_t tx_delay;
uint8_t current_num_to_check;
uint8_t last_safe_tx_power_index = 0;

uint8_t power_change_seq;

#define NUMBER_OF_MISSED_BEACONS	11
#define NUM_RADIO_POWERS 		8

uint8_t neighborhoodCounter;
uint8_t good_quality_neighbors;

uint8_t radio_powers[NUM_RADIO_POWERS] = {31, 27, 23, 19, 15, 11, 7, 3};

NeighborsRssiData my_data[NEIGHBORHOOD_DATA];

message_metadata_t* getMetadata(message_t *msg) {
	return (message_metadata_t*)msg->metadata;
}

task void send_timer() {
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call SendTimer.startOneShot( (call Random.rand16() % tx_delay) + 
			(tx_delay / 2) + 1);
}

void clean_record(uint8_t i) {
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_REMOVE_NODE, my_data[i].node, my_data[i].node, my_data[i].node);
#endif
	my_data[i].node = BROADCAST;
	my_data[i].first_seq = UNKNOWN;
	my_data[i].last_seq = UNKNOWN;
	my_data[i].timestamp = UNKNOWN;
	my_data[i].rec = UNKNOWN;
	my_data[i].radio_tx = UNKNOWN;
	my_data[i].size = UNKNOWN;
	my_data[i].rssi_calib = UNKNOWN;
}

void start_new_radio_tx_test() {
	uint8_t i;

	busy = FALSE;
	neighborhoodCounter = 0;
	good_quality_neighbors = 0;
	seqno = 0;
	current_num_to_check = num_to_check + (call Random.rand16() % num_to_check);

	for ( i = 0 ; i < NEIGHBORHOOD_DATA; i++ ) {
		clean_record(i);
	}

	post send_timer();
}

void updateNeighborhoodCounter() {
	uint8_t i;
	uint8_t neighbors_in_need = 0;
	uint8_t dont_hear_us = 0;
	uint8_t potential_loss = 0;
	good_quality_neighbors = 0;
	neighborhoodCounter = 0;

	for ( i = 0 ; i < NEIGHBORHOOD_DATA; i++ ) {
		if ( my_data[i].node == BROADCAST ) {
			continue;
		}

		if ( my_data[i].rec > 0 ) {
			neighborhoodCounter++;

			if ( my_data[i].size < neighborhood_min_size ) {
				neighbors_in_need++;
			}

			if ( my_data[i].rssi_calib > good_rssi ) {
				good_quality_neighbors++;
				if (my_data[i].radio_tx > tx_power) {
					potential_loss++;
				}
			}
		} else {
			dont_hear_us++;
		}
	}

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] Application NeighborsRssi NeighborCount %u   Good NeighborsRssi %u   In Need %u\n", 
//			process, neighborhoodCounter, good_quality_neighbors, neighbors_in_need);
#else
        call SerialDbgs.dbgs(DBGS_STATUS_UPDATE, neighborhoodCounter, good_quality_neighbors, neighbors_in_need);
#endif
#endif

	if (seqno < current_num_to_check) {
		return;
	}

	if ((good_quality_neighbors > neighborhood_min_size) && (neighbors_in_need <= max_num_of_poor_neighbors)) {
//		if ((good_quality_neighbors - potential_loss) < neighborhood_min_size) {
//			start_new_radio_tx_test();
//			return;
//		}
		if (radio_powers[NUM_RADIO_POWERS-1] == tx_power) {
			/* we are already at the lowest power and can potentially lower it */
			start_new_radio_tx_test();
			last_safe_tx_power_index = NUM_RADIO_POWERS - 1;
			return;
		}
		for( i = 0; i < NUM_RADIO_POWERS; i++) {
			if (radio_powers[i] < tx_power) {
				if (last_safe_tx_power_index + 1 < i) {
					last_safe_tx_power_index++;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
					printf("[%u] Application NeighborsRssi New Safe Channel %d\n", 
							process, radio_powers[last_safe_tx_power_index]);
#else
					call SerialDbgs.dbgs(DBGS_NEW_CHANNEL, process, good_quality_neighbors,
							radio_powers[last_safe_tx_power_index]);
#endif
#endif
				}

				tx_power = radio_powers[i];
				call Param.set(TX_POWER, &tx_power, sizeof(tx_power));
				power_change_seq++;

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
				printf("[%u] Application NeighborsRssi Lower to %d  [ Neighborhood: All: %d   Good: %d   Need Help: %d  Lost: %d ] - potential loss %d\n", 
					process, tx_power, neighborhoodCounter, good_quality_neighbors,
					neighbors_in_need, dont_hear_us, potential_loss);
#else
				call SerialDbgs.dbgs(DBGS_CHANNEL_RESET, power_change_seq, good_quality_neighbors, tx_power);
#endif
#endif
				start_new_radio_tx_test();
				return;
			}
		}
	}

	if (good_quality_neighbors < neighborhood_min_size) {
		for( i = 1; i < NUM_RADIO_POWERS; i++) {
			if (radio_powers[i] == tx_power) {
				if ( i == last_safe_tx_power_index ) {
					/* We already backed-up to the last safe one */
					start_new_radio_tx_test();
					return;
				}

				tx_power = radio_powers[i-1];
				call Param.set(TX_POWER, &tx_power, sizeof(tx_power));
				power_change_seq++;

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
				printf("[%u] Application NeighborsRssi Increase to %d  [ Neighborhood: All: %d   Good: %d   Need Help: %d  Lost: %d ]\n", 
					process, tx_power, neighborhoodCounter, good_quality_neighbors,
					neighbors_in_need, dont_hear_us);
#else
				call SerialDbgs.dbgs(DBGS_CHANNEL_RESET, power_change_seq, good_quality_neighbors, tx_power);
#endif
#endif
				start_new_radio_tx_test();
				return;
			}
		}
	}
	start_new_radio_tx_test();
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
					nx_uint16_t size, int8_t rssi_calib, uint8_t hears_us) {
	uint8_t i;
	uint32_t now_time = call LocalTime.get();

	/* check if there are any old neighbors that should be removed */
	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		if ( (my_data[i].node != BROADCAST) && ( my_data[i].timestamp + (NUMBER_OF_MISSED_BEACONS * tx_delay) < now_time ) ) {
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

	if ( ( my_data[i].node == BROADCAST ) || ( my_data[i].radio_tx != tx ) || ( hears_us != TRUE )) {
		/*   first time                   the node has changed tx power */
		my_data[i].node = src;
		my_data[i].first_seq = seq;
		my_data[i].rec = 0;
		my_data[i].rssi_calib = -126;
#ifdef __DBGS__APPLICATION__
		call SerialDbgs.dbgs(DBGS_ADD_NODE, src, tx, hears_us);
#endif
	}

	my_data[i].rec++;
	my_data[i].size = size;
	my_data[i].last_seq = seq;
	my_data[i].timestamp = now_time;
	my_data[i].radio_tx = tx;
	if (rssi_calib > my_data[i].rssi_calib) {
		my_data[i].rssi_calib = rssi_calib;
	}

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] Application NeighborsRssi Update: Node %d   NSize %d   TX %d   Rec %d   ETX %d\n",
//			process, src, size, tx, my_data[i].rec, my_data[i].rec * 100 / seq);
#else
	call SerialDbgs.dbgs(DBGS_GOT_RECEIVE, src, my_data[i].rec, seq);
#endif
#endif
	updateNeighborhoodCounter();
}

command error_t SplitControl.start() {

	call Param.get(NEIGHBORHOOD_MIN_SIZE, &neighborhood_min_size, sizeof(neighborhood_min_size));
	call Param.get(MAX_NUM_OF_POOR_NEIGHBORS, &max_num_of_poor_neighbors, sizeof(max_num_of_poor_neighbors));
	call Param.get(GOOD_RSSI, &good_rssi, sizeof(good_rssi));
	call Param.get(TX_POWER, &tx_power, sizeof(tx_power));
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call Param.get(NUM_TO_CHECK, &num_to_check, sizeof(num_to_check));
        call Param.get(RSSI_SCALE, &rssi_scale, sizeof(rssi_scale));
        call Param.get(RSSI_OFFSET, &rssi_offset, sizeof(rssi_offset));

	last_safe_tx_power_index = 0;
	power_change_seq = 0;

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Neighbor start()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif
	start_new_radio_tx_test();
	
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call SendTimer.stop();

	tx_power = radio_powers[last_safe_tx_power_index];
	call Param.set(TX_POWER, &tx_power, sizeof(tx_power));

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application NeighborsRssi Final set to %d\n", process, tx_power);
#else
	call SerialDbgs.dbgs(DBGS_CHANNEL_RESET, process, good_quality_neighbors, tx_power);
#endif
#endif

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Neighbor stop()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
	post send_timer();
#ifdef __DBGS__APPLICATION__
        call SerialDbgs.dbgs(DBGS_SEND_DATA, error, seqno, tx_power);
#endif
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t i;
	int8_t rssi = (int8_t) call SubPacketRSSI.get(msg);
	int8_t rssi_calib = (rssi * rssi_scale) + rssi_offset;
	NeighborsRssiMsg *m = (NeighborsRssiMsg*) payload;

	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		if (m->data[i].node == TOS_NODE_ID) {
			/* this node hears us */
			if ( m->data[i].radio_tx == tx_power ) {
				/* this node hears us with the current radio control */
				add_receive_node(m->src, m->tx, m->seq, m->size, rssi_calib, TRUE);
				return msg;
			} else {
				/* here are nodes that we lost since power upgrade */
				/* this node does not know about us anymore */
			}
			break;
		}
	}

	/* case when a node does not hears us... */
	/* may be the case that it used to hear us, but only has older tx_power */
	/* this node does not know about us */
	add_receive_node(m->src, m->tx, m->seq, m->size, rssi_calib, FALSE);
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	uint8_t i;
	NeighborsRssiMsg *msg = (NeighborsRssiMsg*) call SubAMSend.getPayload(&packet,
							sizeof(NeighborsRssiMsg));

	if (msg == NULL || busy) {
		post send_timer();
	}

	busy = TRUE;
	call Param.get(TX_POWER, &tx_power, sizeof(tx_power));
	msg->src = TOS_NODE_ID;
	msg->tx = tx_power;
	msg->seq = ++seqno;
	msg->size = good_quality_neighbors;
	for ( i = 0; i < NEIGHBORHOOD_DATA; i++ ) {
		msg->data[i].node = my_data[i].node;
		msg->data[i].radio_tx = my_data[i].radio_tx;
		msg->data[i].rssi_calib = my_data[i].rssi_calib;
	}

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(NeighborsRssiMsg)) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	}
}

event void Param.updated(uint8_t var_id) {

}

}
