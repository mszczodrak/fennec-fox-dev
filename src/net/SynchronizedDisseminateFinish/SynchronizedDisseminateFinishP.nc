#include <Fennec.h>
#include "SynchronizedDisseminateFinish.h"

#include "CC2420TimeSyncMessage.h"

#define _MILLI_2_32KHZ(x) ((x) << 5)
#define _32KHZ_2_MILLI(x) ((x) >> 5)

#define MILLI_SEC_1	(1 << 5)
#define MILLI_SEC_2	(2 << 5)
#define MILLI_SEC_3	(3 << 5)

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

uses interface Leds;
uses interface Timer<TMilli> as SendTimer;
uses interface Timer<TMilli> as FinishTimer;

uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;

uses interface LocalTime<T32khz> as LocalTime;

}

implementation {

uint16_t delay;
uint8_t repeat;
bool busy = FALSE;

message_t packet;

uint8_t packet_payload_len;

message_t *app_pkt = NULL;

void start_finish_timer(uint32_t t0, uint32_t dt) {
	//printf("[%u] SynchronizedDisseminateFinish start_finish_timer %lu %lu\n", process, t0, dt);
	call FinishTimer.startOneShotAt(t0, dt);
	//printf("[%u] SynchronizedDisseminateFinish FinishTimer will fire at %lu\n", process, call FinishTimer.gett0() + call FinishTimer.getdt());
}

void send_message() {
	uint32_t now_32khz = call LocalTime.get();
	uint8_t *payload = (uint8_t*)call Packet.getPayload(&packet, packet_payload_len);
	nx_struct SDF_header *header = (nx_struct SDF_header *) call SubAMSend.getPayload(&packet, 
				sizeof(nx_struct SDF_header) + packet_payload_len + sizeof(nx_struct SDF_footer));
	nx_struct SDF_footer *footer = (nx_struct SDF_footer*)(payload + packet_payload_len);

	if (busy) {
		signal SubAMSend.sendDone(&packet, SUCCESS);
		return;
	}

	call SubPacketTimeSyncOffset.set(&packet, now_32khz);

	footer->offset = now_32khz;
	header->left = _MILLI_2_32KHZ(call FinishTimer.gett0() + call FinishTimer.getdt());

	if (header->left <= now_32khz) {
		return;
	}

	header->left -= now_32khz;

	/* skip if less than 2ms left */
	if (header->left < MILLI_SEC_3) {
		return;
	}
	
	//printf("[%u] SynchronizedDisseminateFinish sending left: %lu timestamp: %lu\n", process, header->left, footer->offset);

	if (call SubAMSend.send(BROADCAST, &packet, packet_payload_len +
					sizeof(nx_struct SDF_header) +
					sizeof(nx_struct SDF_footer) ) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		busy = TRUE;
	}
}

void make_copy(message_t *msg, void *new_payload, uint8_t new_payload_len) {
	void* payload = call Packet.getPayload(&packet, new_payload_len);
	nx_struct SDF_header *header = (nx_struct SDF_header *) call SubAMSend.getPayload(&packet,
				sizeof(nx_struct SDF_header) + packet_payload_len + sizeof(nx_struct SDF_footer));

	memcpy(payload, new_payload, new_payload_len);

	call Param.get(DELAY, &delay, sizeof(delay));
	call SendTimer.startPeriodic(delay);

	packet_payload_len = new_payload_len;

	header->crc = (nx_uint16_t) crc16(0, payload, packet_payload_len);
	send_message();
}

bool same_packet(void *in_payload, uint8_t in_len) {
	void* payload = call Packet.getPayload(&packet, packet_payload_len);
	return ((in_len == packet_payload_len) && !(memcmp(in_payload, payload, in_len)));
}

command error_t SplitControl.start() {
	app_pkt = NULL;
	busy = FALSE;

	call Param.get(REPEAT, &repeat, sizeof(repeat));
	call Param.get(DELAY, &delay, sizeof(delay));

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	busy = FALSE;
	call SendTimer.stop();
	call FinishTimer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SendTimer.fired() {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] SynchronizedDisseminateFinish SendTimer fired\n", process);
#endif
	send_message();
	return;
}


event void FinishTimer.fired() {
	call SendTimer.stop();
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] SynchronizedDisseminateFinish FinishTimer fired\n", process);
#endif
	if ( app_pkt != NULL ) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] SynchronizedDisseminateFinish signal sendDone\n", process);
#endif
		signal AMSend.sendDone(app_pkt, SUCCESS);
	}
	app_pkt = NULL;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	uint32_t now = call FinishTimer.getNow();
	void *app_payload = call Packet.getPayload(msg, len);
	app_pkt = msg;
	if (same_packet(app_payload, len)) {
		if (call FinishTimer.isRunning()) {
			return SUCCESS;
		}
		start_finish_timer( now, repeat / 2 * delay );
		make_copy(msg, app_payload, len);
		return SUCCESS;	
	}

	start_finish_timer( now, repeat * delay );
	make_copy(msg, app_payload, len);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
//	printf("[%u] SynchronizedDisseminateFinish sends new version of payload\n", process);
#endif
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
}

event message_t* SubReceive.receive(message_t *msg, void* in_payload, uint8_t in_len) {
	uint32_t receiver_receive_time_estimate = call LocalTime.get();
        nx_struct SDF_header *header = (nx_struct SDF_header *) in_payload;
	uint8_t *payload = ((uint8_t*) in_payload) + sizeof(nx_struct SDF_header);
	uint8_t len = in_len - sizeof(nx_struct SDF_header) - sizeof(nx_struct SDF_footer);
        nx_struct SDF_footer *footer = (nx_struct SDF_footer*)(payload + len);
	
	uint32_t sender_time_left;
	uint32_t receiver_receive_time;
	uint32_t receiver_time_left = 0;

	if (header->crc != (nx_uint16_t) crc16(0, payload, len)) {
		return msg;
	}

	if (call SubPacketTimeStamp32khz.isValid(msg)) {
		receiver_receive_time = call SubPacketTimeStamp32khz.timestamp(msg);
	} else {
		receiver_receive_time = receiver_receive_time_estimate;
	}

	if (header->left <= -(footer->offset)) {
		sender_time_left = MILLI_SEC_1;
	} else {
		sender_time_left = header->left + footer->offset;
	}

	receiver_time_left = _MILLI_2_32KHZ(call FinishTimer.gett0() + call FinishTimer.getdt()) - receiver_receive_time;

	if (! call FinishTimer.isRunning()) {
		receiver_time_left = 0;
	}

	if (same_packet(payload, len)) {
		if (receiver_time_left) {
			if ( 	call SubPacketTimeStamp32khz.isValid(msg) 		&& 
				(receiver_time_left > (sender_time_left + MILLI_SEC_1)) 	&& 
				(sender_time_left > MILLI_SEC_2) ) {
//				printf("[%u] SynchronizedDisseminateFinish receive at %lu: sender_sent_left %lu - adjust\n", process, 
//					receiver_receive_time, sender_time_left);
//				start_finish_timer( _32KHZ_2_MILLI(receiver_receive_time), _32KHZ_2_MILLI(sender_time_left) );
			}
		}
                return msg;
        }

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] SynchronizedDisseminateFinish received new version of payload %lu %lu -> %lu %lu\n", process,
			receiver_receive_time, sender_time_left, _32KHZ_2_MILLI(receiver_receive_time), _32KHZ_2_MILLI(sender_time_left) );
#endif
	start_finish_timer( _32KHZ_2_MILLI(receiver_receive_time), _32KHZ_2_MILLI(sender_time_left) );
	make_copy(msg, payload, len);
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
