#include <Fennec.h>
#include "reTrickle.h"

#include "CC2420TimeSyncMessage.h"

#define MILLI_2_32KHZ(x) ((x) << 5)

generic module reTrickleP(process_t process) {
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

uint8_t receive_same_packet;
uint8_t suppress;

uint8_t packet_payload_len;

message_t *app_pkt = NULL;
nx_struct reTrickle_header *header = NULL;

void do_clean() {
	app_pkt = NULL;
	packet_payload_len = 0;
	header = NULL;
}

void start_finish_timer(uint32_t t0, uint32_t dt) {
	printf("[%u] reTrickle start_finish_timer %lu %lu   and now %lu\n", process, t0, dt, call FinishTimer.getNow());
	call FinishTimer.startOneShotAt(t0, dt);
	//printf("[%u] reTrickle FinishTimer will fire at %lu\n", process, call FinishTimer.gett0() + call FinishTimer.getdt());
}

void send_message() {
	uint32_t now_32khz = call LocalTime.get();
	uint8_t *payload = (uint8_t*)call Packet.getPayload(&packet, packet_payload_len);
	nx_uint32_t *timestamp = (nx_uint32_t*)(payload + packet_payload_len);

	if (busy) {
		signal SubAMSend.sendDone(&packet, SUCCESS);
		return;
	}

	call SubPacketTimeSyncOffset.set(&packet, now_32khz);

	*timestamp = now_32khz;
	header->left = ((call FinishTimer.gett0() + call FinishTimer.getdt()) << 5) - now_32khz;
	
	printf("[%u] reTrickle sending left: %lu timestamp: %lu\n", process, header->left, *timestamp);

	if (call SubAMSend.send(BROADCAST, &packet, packet_payload_len + sizeof(nx_struct reTrickle_header) + sizeof(*timestamp) ) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		busy = TRUE;
	}
}

void make_copy(message_t *msg, void *new_payload, uint8_t new_payload_len) {
	void* payload = call Packet.getPayload(&packet, new_payload_len);
	memcpy(&packet, msg, sizeof(message_t));
	header = (nx_struct reTrickle_header*) call SubAMSend.getPayload(&packet, 
					new_payload_len +
					sizeof(nx_struct reTrickle_header));

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
	do_clean();
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
	printf("[%u] reTrickle SendTimer fired\n", process);
#endif

	call Param.get(SUPPRESS, &suppress, sizeof(suppress));

	if (receive_same_packet < suppress) {
		send_message();
	}
	receive_same_packet = 0;
	return;
}


event void FinishTimer.fired() {
	call SendTimer.stop();
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] reTrickle FinishTimer fired\n", process);
#endif
	if ( app_pkt != NULL ) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] reTrickle signal sendDone\n", process);
#endif
		signal AMSend.sendDone(app_pkt, SUCCESS);
	}
	do_clean();
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	uint32_t now = call FinishTimer.getNow();
	void *app_payload = call Packet.getPayload(msg, len);
	app_pkt = msg;
	if (same_packet(app_payload, len)) {
		if (call FinishTimer.isRunning()) {
			return SUCCESS;
		}
		start_finish_timer( now, 3 * delay );
		make_copy(msg, app_payload, len);
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] reTrickle re-sends the same version of payload\n", process);
#endif
		return SUCCESS;	
	}

	printf("[%u] reTrickle AMSend.send now: %lu\n", process, now);
	start_finish_timer( now, repeat * delay );
	make_copy(msg, app_payload, len);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] reTrickle sends new version of payload\n", process);
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

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t in_len) {
	uint8_t *in_payload = (uint8_t*) payload;
	nx_struct reTrickle_header *in_hdr = (nx_struct reTrickle_header*) payload;
	nx_struct reTrickle_footer *in_fdr;

	nx_uint32_t sender_time_left;
	uint32_t receiver_receive_time;
	uint32_t receiver_time_left = 0;

	in_len -= (sizeof(nx_struct reTrickle_header) + sizeof(nx_struct reTrickle_footer));
	in_payload += sizeof(nx_struct reTrickle_header);
	in_fdr = (nx_struct reTrickle_footer*) (in_payload + in_len);

	if (in_hdr->crc != (nx_uint16_t) crc16(0, in_payload, in_len)) {
		return msg;
	}

	sender_time_left = in_hdr->left;

	receiver_receive_time = (uint32_t) call SubPacketTimeStamp32khz.timestamp(msg);

	if (receiver_receive_time < -in_fdr->offset) {
		return msg;
	}

	printf("[%u] reTrickle sender_sent_left %lu = %lu + %lu\n", process, 
			sender_time_left + in_fdr->offset, sender_time_left, in_fdr->offset);
	
	sender_time_left += in_fdr->offset;


	/* At the moment of receive, how much time was left for receiver */

	if (call FinishTimer.isRunning()) {
		receiver_time_left = ((call FinishTimer.gett0() + call FinishTimer.getdt()) << 5) - receiver_receive_time;
	}

	if (same_packet(in_payload, in_len)) {
		if (call FinishTimer.isRunning()) {
			receive_same_packet++;
			if (receiver_time_left > sender_time_left + 100) {
				start_finish_timer( receiver_receive_time >> 5, sender_time_left >> 5 );
				printf("[%u] reTrickle sender adjusted clock r:%lu > s:%lu\n", process,
					receiver_time_left, sender_time_left);
			}
		}
                return msg;
        }

	start_finish_timer( receiver_receive_time >> 5, sender_time_left >> 5);
	make_copy(msg, in_payload, in_len);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] reTrickle received new version of payload\n", process);
#endif
	return signal Receive.receive(msg, in_payload, in_len);
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *in_payload = (uint8_t*) payload;
	uint8_t in_len = len -= sizeof(nx_struct reTrickle_header);
	in_payload += sizeof(nx_struct reTrickle_header);

	return signal Snoop.receive(msg, in_payload, in_len);
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
			sizeof(nx_struct reTrickle_header) -
			sizeof(nx_struct reTrickle_footer));
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr;
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, len + 
				sizeof(nx_struct reTrickle_header));
	return (void*) (ptr + sizeof(nx_struct reTrickle_header));
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
