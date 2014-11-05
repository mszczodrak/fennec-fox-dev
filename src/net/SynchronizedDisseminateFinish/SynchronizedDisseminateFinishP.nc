#include <Fennec.h>
#include "SynchronizedDisseminateFinish.h"

generic module SynchronizedDisseminateFinishP(process_t process) {
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
message_t *app_pkt = NULL;
bool new_data = FALSE;
bool sync;

uint32_t start_32khz;
uint32_t end_32khz;
uint32_t delay_32khz;
uint32_t radio_tx_offset = 5;	/* 5 */

void send_message() {
	uint32_t now_32khz = call Alarm.getNow();
	uint8_t *payload = (uint8_t*)call Packet.getPayload(&packet, packet_payload_len);
	nx_struct SDF_header *header = (nx_struct SDF_header *) call SubAMSend.getPayload(&packet, 
				sizeof(nx_struct SDF_header) + packet_payload_len + sizeof(nx_struct SDF_footer));
	nx_struct SDF_footer *footer = (nx_struct SDF_footer*)(payload + packet_payload_len);

	if (busy) {
		return;
	}

	busy = TRUE;

	header->left = end_32khz - now_32khz;
	footer->offset = now_32khz;
	call SubPacketTimeStamp32khz.set(&packet, now_32khz);

	if (call SubAMSend.send(BROADCAST, &packet, packet_payload_len +
					sizeof(nx_struct SDF_header) +
					sizeof(nx_struct SDF_footer) ) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	}
}

void make_copy(message_t *msg, void *new_payload, uint8_t new_payload_len) {
	void* payload = call Packet.getPayload(&packet, new_payload_len);
	nx_struct SDF_header *header = (nx_struct SDF_header *) call SubAMSend.getPayload(&packet,
				sizeof(nx_struct SDF_header) + packet_payload_len + sizeof(nx_struct SDF_footer));

	memcpy(payload, new_payload, new_payload_len);
	packet_payload_len = new_payload_len;

	header->crc = (nx_uint16_t) crc16(0, payload, packet_payload_len);
	send_message();
	call SendTimer.startPeriodic(2);
}

bool same_packet(void *in_payload, uint8_t in_len) {
	void* payload = call Packet.getPayload(&packet, packet_payload_len);
	return ((in_len == packet_payload_len) && !(memcmp(in_payload, payload, in_len)));
}

void setup_alarm(uint32_t d0, uint32_t dt ) {
	call Alarm.startAt( d0, dt );
	end_32khz = d0 + dt + 1;
}

command error_t SplitControl.start() {
	app_pkt = NULL;
	busy = FALSE;
	sync = FALSE;

#ifdef __FLOCKLAB_LEDS__
	call Leds.led2Off();
#endif

	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(DELAY, &delay, sizeof(delay));
	delay_32khz = _MILLI_2_32KHZ( repeat * delay );

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	busy = FALSE;
	call SendTimer.stop();
	call Alarm.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SendTimer.fired() {
	if (!call Alarm.isRunning()) {
		call SendTimer.stop();
		return;
	}

	if (!busy) {
		send_message();
	}

	call Param.get(DELAY, &delay, sizeof(delay));
	call SendTimer.startPeriodic((delay / 2) + call Random.rand16() % delay);
}

task void finish() {
	call SendTimer.stop();
	if (new_data) {
#ifdef __FLOCKLAB_LEDS__
		call Leds.led2On();
#endif
		call Param.set(LAST_FINISH, &end_32khz, sizeof(end_32khz));
	}
	if ( app_pkt != NULL ) {
#ifdef __DBGS__NETWORK_ACTIONS__
		if (new_data) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] SDF signal sendDone\n", process);
#else
			call SerialDbgs.dbgs(DBGS_SIGNAL_FINISH_PERIOD, process, 0, 0);
#endif
		}
#endif
		signal AMSend.sendDone(app_pkt, SUCCESS);
	} else {
#ifdef __DBGS__NETWORK_ACTIONS__
		if (new_data) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] SDF signal sendDone (does not signal)\n", process);
#else
			call SerialDbgs.dbgs(DBGS_FINISH_PERIOD, process, 0, 0);
#endif
		}
#endif
	}
	new_data = FALSE;
	app_pkt = NULL;
}

async event void Alarm.fired() {
	post finish();
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	void *app_payload;
	start_32khz = call Alarm.getNow();
	app_payload = call Packet.getPayload(msg, len);
	app_pkt = msg;
	sync = FALSE;

	if (same_packet(app_payload, len)) {
		if (call Alarm.isRunning()) {
			return SUCCESS;
		}
		send_message();
		post finish();
		return SUCCESS;	
	}

	setup_alarm( start_32khz, delay_32khz );
	make_copy(msg, app_payload, len);
	new_data = TRUE;
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
	sync = TRUE;
}

event message_t* SubReceive.receive(message_t *msg, void* in_payload, uint8_t in_len) {
	uint32_t now = call Alarm.getNow();
	uint32_t receiver_receive_time = call SubPacketTimeStamp32khz.timestamp(msg);
        nx_struct SDF_header *header = (nx_struct SDF_header *) in_payload;
	uint8_t *payload = ((uint8_t*) in_payload) + sizeof(nx_struct SDF_header);
	uint8_t len = in_len - sizeof(nx_struct SDF_header) - sizeof(nx_struct SDF_footer);
        nx_struct SDF_footer *footer = (nx_struct SDF_footer*)(payload + len);
	uint32_t sender_time_left = header->left + footer->offset;

	if (header->crc != (nx_uint16_t) crc16(0, payload, len)) {
		return msg;
	}

	/* calibrate sender timestamp */
	/* remove default radio_tx_offset from the sender timestamp */
	//sender_time_left -= radio_tx_offset;
	
	if (same_packet(payload, len)) {
		if ( call Alarm.isRunning() && 
				call SubPacketTimeStamp32khz.isValid(msg) && 
				(sender_time_left < delay_32khz) &&
				((receiver_receive_time + sender_time_left) < end_32khz) && 
				(sync == TRUE) ) {
			setup_alarm( receiver_receive_time, sender_time_left );
			sync = FALSE;
		}
                return msg;
        }

	if ( (sender_time_left < delay_32khz) && (call SubPacketTimeStamp32khz.isValid(msg)) ) {
		setup_alarm( receiver_receive_time, sender_time_left );
	} else {
		setup_alarm( now, delay_32khz );
	}
	sync = FALSE;
	make_copy(msg, payload, len);
	new_data = TRUE;
	return signal Receive.receive(msg, payload, len);
}

event message_t* SubSnoop.receive(message_t *msg, void* in_payload, uint8_t in_len) {
	uint8_t *payload = ((uint8_t*) in_payload) + sizeof(nx_struct SDF_header);
	uint8_t len = in_len - sizeof(nx_struct SDF_header) - sizeof(nx_struct SDF_footer);
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
			sizeof(nx_struct SDF_header) -
			sizeof(nx_struct SDF_footer));
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr;
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, len + 
				sizeof(nx_struct SDF_header));
	return (void*) (ptr + sizeof(nx_struct SDF_header));
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

event void Param.updated(uint8_t var_id) {

}


}
