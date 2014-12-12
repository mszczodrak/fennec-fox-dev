#include <Fennec.h>
#include "EED.h"

generic module EEDP(process_t process) @safe() {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;

uses interface Leds;
uses interface Timer<TMilli> as SendTimer;
uses interface Alarm<T32khz, uint32_t>;
uses interface Random;
uses interface SerialDbgs;
}

implementation {

uint16_t delay;
uint8_t repeat;
bool busy = FALSE;
message_t packet;
uint8_t packet_payload_len;
norace message_t *app_pkt = NULL;
norace bool new_data = FALSE;
bool once = FALSE;

norace uint32_t end_32khz;
uint32_t delay_32khz = 0;
//uint32_t radio_tx_offset = 2;	/* 2 */
uint16_t receive_counter = 0;

task void send_message() {
	uint8_t *payload = (uint8_t*)call Packet.getPayload(&packet, packet_payload_len);
	nx_struct EED_header *header = (nx_struct EED_header *) call SubAMSend.getPayload(&packet, 
				sizeof(nx_struct EED_header) + packet_payload_len + sizeof(nx_struct EED_footer));
	nx_struct EED_footer *footer = (nx_struct EED_footer*)(payload + packet_payload_len);
        header->now = call Alarm.getNow();

	if (busy) {
		signal SubAMSend.sendDone(&packet, FAIL);
		return;
	}

	busy = TRUE;
        header->left = end_32khz;
        header->left -= header->now;
	footer->left = end_32khz;
	call SubPacketTimeStamp32khz.set(&packet, end_32khz);

	if (call SubAMSend.send(BROADCAST, &packet, packet_payload_len +
					sizeof(nx_struct EED_header) +
					sizeof(nx_struct EED_footer) ) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	}
}

void make_copy(message_t *msg, void *new_payload, uint8_t new_payload_len) {
	void* payload = call Packet.getPayload(&packet, new_payload_len);
	nx_struct EED_header *header = (nx_struct EED_header *) call SubAMSend.getPayload(&packet,
				sizeof(nx_struct EED_header) + packet_payload_len + sizeof(nx_struct EED_footer));

	memcpy(payload, new_payload, new_payload_len);
	packet_payload_len = new_payload_len;
	new_data = TRUE;
	header->crc = (nx_uint16_t) crc16(0, payload, packet_payload_len);
}

bool same_packet(void *in_payload, uint8_t in_len) {
	void* payload = call Packet.getPayload(&packet, packet_payload_len);
	return ((in_len == packet_payload_len) && !(memcmp(in_payload, payload, in_len)));
}

void setup_alarm(uint32_t d0, uint32_t dt ) {
	uint32_t soon = call Alarm.getNow();
	end_32khz = d0 + dt;
	if (dt == 0) {
		call Alarm.start(2);
	}
	soon -= 3;
	if (end_32khz > soon) {
		call Alarm.startAt( d0, dt );
	}
}

task void startDone() {
	signal SplitControl.startDone(SUCCESS);
}

task void stopDone() {
	signal SplitControl.stopDone(SUCCESS);
}

command error_t SplitControl.start() {
	app_pkt = NULL;
	busy = FALSE;
	new_data = FALSE;
	once = FALSE;
	receive_counter = 0;

#ifdef __FLOCKLAB_LEDS__
	call Leds.led2Off();
#endif

	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(DELAY, &delay, sizeof(delay));
	delay_32khz = _MILLI_2_32KHZ( repeat * delay );

	post startDone();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	busy = FALSE;
	receive_counter = 0;
	once = FALSE;
	call SendTimer.stop();
	call Alarm.stop();
	delay_32khz = 0;
	post stopDone();
	return SUCCESS;
}

event void SendTimer.fired() {
	if (!call Alarm.isRunning()) {
		call SendTimer.stop();
		return;
	}

	if (!busy || (receive_counter <= SUPPRESS_BROADCAST)) {
		post send_message();
	}

	receive_counter = 0;

	call Param.get(DELAY, &delay, sizeof(delay));
	call SendTimer.startPeriodic((delay / 2) + call Random.rand16() % delay);
}

task void finish() {
	call SendTimer.stop();

	if ( new_data ) {
		call Param.set(LAST_FINISH, &end_32khz, sizeof(end_32khz));
		new_data = FALSE;
	}

	if ( app_pkt ) {
		signal AMSend.sendDone(app_pkt, SUCCESS);
		app_pkt = NULL;
	}
}

void quick_send() {
	call SendTimer.startPeriodic((call Random.rand16() % delay) + 1);
}

async event void Alarm.fired() {
	if ( new_data && app_pkt ) {
#ifdef __FLOCKLAB_LEDS__
		call Leds.led2On();
#endif

#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] EED signal sendDone                  T %lu\n", process, end_32khz);
#else
		call SerialDbgs.dbgs(DBGS_SIGNAL_FINISH_PERIOD, 0, 
				(uint16_t)(end_32khz >> 16), (uint16_t) end_32khz);
#endif
#endif
	}
	post finish();
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	uint32_t now = call Alarm.getNow();
	void *app_payload = call Packet.getPayload(msg, len);
	app_pkt = msg;
	once = FALSE;

	if (same_packet( app_payload, len )) {
		if (call Alarm.isRunning()) {
			return SUCCESS;
		}
		once = TRUE;
		quick_send();
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] EED old local send                   T %lu\n", process, now);
#else
		call SerialDbgs.dbgs(DBGS_SAME_LOCAL_PAYLOAD, process, (uint16_t)(now >> 16), (uint16_t)now);
#endif
#endif
	} else {
		setup_alarm( now, delay_32khz );
		make_copy(msg, app_payload, len);
		quick_send();
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] EED new local send                   T %lu\n", process, delay_32khz);
#else
		call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, 0, (uint16_t)(delay_32khz >> 16), (uint16_t)delay_32khz);
#endif
#endif
	}
	return SUCCESS;
}

command error_t AMSend.cancel(message_t* msg) {
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	return call Packet.maxPayloadLength();
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	return call Packet.getPayload(msg, len);
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
	if (once == TRUE) {
		signal AMSend.sendDone(app_pkt, error);
		once = FALSE;
		app_pkt = NULL;
	}
}

event message_t* SubReceive.receive(message_t *msg, void* in_payload, uint8_t in_len) {
	uint32_t now = call Alarm.getNow();
	uint32_t receiver_receive_time = call SubPacketTimeStamp32khz.timestamp(msg);
        nx_struct EED_header *header = (nx_struct EED_header *) in_payload;
	uint8_t *payload = ((uint8_t*) in_payload) + sizeof(nx_struct EED_header);
	uint8_t len = in_len - sizeof(nx_struct EED_header) - sizeof(nx_struct EED_footer);
        nx_struct EED_footer *footer = (nx_struct EED_footer*)(payload + len);
	uint32_t sender_time_left = footer->left;
	uint32_t new_end;
	uint8_t payload_copy[100];
	memcpy(&payload_copy, payload, len);
	payload = payload_copy;

	receive_counter++;

	if (header->crc != (nx_uint16_t) crc16(0, payload, len)) {
		return msg;
	}

	/* calibrate sender timestamp */
	/* remove default radio_tx_offset from the sender timestamp */
	//sender_time_left -= radio_tx_offset;

	if (delay_32khz == 0) {
	        call Param.get(REPEAT, &repeat, sizeof(repeat));
        	call Param.get(DELAY, &delay, sizeof(delay));
	        delay_32khz = _MILLI_2_32KHZ( repeat * delay );
	}

	if (! call SubPacketTimeStamp32khz.isValid(msg)) {
		receiver_receive_time = now;
	}

	new_end = receiver_receive_time + sender_time_left;

	if (same_packet(payload, len)) {
		if ( call Alarm.isRunning() && 
				//((sender_time_left < delay_32khz) || (sender_time_left > -delay_32khz)) &&
				//(new_end < (end_32khz - 10))) {
				(new_end < end_32khz)) {

			if ((new_end < now) || (sender_time_left > (-delay_32khz))) {
				setup_alarm(new_end, 0);
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//				printf("[%u] EED same remote payload from %3u  got past %lu < %lu or %lu > %lu\n", process, 
//					call SubAMPacket.source(msg), new_end, now, sender_time_left, -delay_32khz);
#else
				call SerialDbgs.dbgs(DBGS_SAME_REMOTE_PAYLOAD, 0, 0, 0);
#endif
#endif
			} else {
				uint32_t adjust_by = end_32khz;
				setup_alarm( receiver_receive_time, sender_time_left );
				adjust_by -= new_end;
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//				printf("[%u] EED same remote payload from %3u     T %lu @ %lu, adjust by %lu\n", process, 
//					call SubAMPacket.source(msg), sender_time_left, receiver_receive_time, adjust_by);
#else
				call SerialDbgs.dbgs(DBGS_SAME_REMOTE_PAYLOAD, (uint16_t)adjust_by,
					(uint16_t)(sender_time_left >> 16),
					(uint16_t)sender_time_left);
#endif
#endif
			}
			quick_send();
		}
                return msg;
        }

	if ((new_end < now) || (sender_time_left > (-delay_32khz))) {
		setup_alarm(new_end, 0);
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//		printf("[%u] EED  new remote payload from %3u  got past %lu < %lu or %lu > %lu\n", process, 
//				call SubAMPacket.source(msg), new_end, now, sender_time_left, -delay_32khz);
#else
		call SerialDbgs.dbgs(DBGS_NEW_REMOTE_PAYLOAD, 0, 0, 0);
#endif
#endif
	} else {
		setup_alarm( receiver_receive_time, sender_time_left );
#ifdef __DBGS__NETWORK_ACTIONS__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//		printf("[%u] EED  new remote payload from %3u     T %lu @ %lu\n", process,
//					call SubAMPacket.source(msg), sender_time_left, receiver_receive_time);
#else
		call SerialDbgs.dbgs(DBGS_NEW_REMOTE_PAYLOAD, 1, 
				(uint16_t)(sender_time_left >> 16),
				(uint16_t)sender_time_left);
#endif
#endif
	}
	make_copy(msg, payload, len);
	quick_send();
	return signal Receive.receive(msg, payload, len);
}

event message_t* SubSnoop.receive(message_t *msg, void* in_payload, uint8_t in_len) {
	uint8_t *payload = ((uint8_t*) in_payload) + sizeof(nx_struct EED_header);
	uint8_t len = in_len - sizeof(nx_struct EED_header) - sizeof(nx_struct EED_footer);
	return signal Snoop.receive(msg, payload, len);
}

command am_addr_t AMPacket.address() {
	return call SubAMPacket.address();
}

command am_addr_t AMPacket.destination(message_t* amsg) {
	return call SubAMPacket.destination(amsg);
}

command am_addr_t AMPacket.source(message_t* amsg) {
	return call SubAMPacket.source(amsg);
}

command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setDestination(amsg, addr);
}

command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setSource(amsg, addr);
}

command bool AMPacket.isForMe(message_t* amsg) {
	return call SubAMPacket.isForMe(amsg);
}

command am_id_t AMPacket.type(message_t* amsg) {
	return call SubAMPacket.type(amsg);
}

command void AMPacket.setType(message_t* amsg, am_id_t t) {
	return call SubAMPacket.setType(amsg, t);
}

command am_group_t AMPacket.group(message_t* amsg) {
	return call SubAMPacket.group(amsg);
}

command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call SubAMPacket.setGroup(amsg, grp);
}

command am_group_t AMPacket.localGroup() {
	return call SubAMPacket.localGroup();
}

command void Packet.clear(message_t* msg) {
	return call SubPacket.clear(msg);
}

command uint8_t Packet.payloadLength(message_t* msg) {
	return call Packet.payloadLength(msg);
}

command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
	return call SubPacket.setPayloadLength(msg, len);
}

command uint8_t Packet.maxPayloadLength() {
	return (call SubAMSend.maxPayloadLength() -
			sizeof(nx_struct EED_header) -
			sizeof(nx_struct EED_footer));
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr;
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, len + 
				sizeof(nx_struct EED_header));
	return (void*) (ptr + sizeof(nx_struct EED_header));
}

async command error_t PacketAcknowledgements.requestAck( message_t* msg ) {
	return call SubPacketAcknowledgements.requestAck(msg);
}

async command error_t PacketAcknowledgements.noAck( message_t* msg ) {
	return call SubPacketAcknowledgements.noAck(msg);
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return call SubPacketAcknowledgements.wasAcked(msg);
}

event void RadioChannel.setChannelDone() {
}

event void Param.updated(uint8_t var_id, bool conflict) {

}


}
