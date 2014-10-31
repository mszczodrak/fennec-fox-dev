#include <Fennec.h>
#include "reTrickle.h"

#define MILLI_2_32KHZ(x) x << 5

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

uses interface Alarm<T32khz,uint32_t> as FinishTimer;

uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;

}

implementation {

uint16_t delay;
uint8_t repeat;
bool busy = FALSE;

uint8_t receive_same_packet;
uint8_t suppress;

bool signal_send_done;
message_t packet;
uint8_t packet_len;


void start_finish_timer(uint32_t t0, uint32_t dt) {
	call FinishTimer.startAt(t0, dt);
}

void send_message() {
	uint8_t *ptr = call SubAMSend.getPayload(&packet, packet_len +
					sizeof(nx_struct reTrickle_header) +
					sizeof(nx_struct reTrickle_footer));

	nx_struct reTrickle_header* hdr = (nx_struct reTrickle_header*) ptr;
	nx_struct reTrickle_footer* fdr = (nx_struct reTrickle_footer*) ptr + 
				packet_len + sizeof(nx_struct reTrickle_header);

	if (busy) {
		signal SubAMSend.sendDone(&packet, SUCCESS);
		return;
	}


	atomic hdr->left = call FinishTimer.getAlarm() - call FinishTimer.getNow();
	fdr->offset = hdr->left;

	call SubPacketTimeSyncOffset.set(&packet, hdr->left);
	

	if (call SubAMSend.send(BROADCAST, &packet, packet_len + 
			sizeof(nx_struct reTrickle_header) +
			sizeof(nx_struct reTrickle_footer)) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		busy = TRUE;
	}
}

void make_copy(void *new_payload, uint8_t new_payload_len) {
	uint8_t *ptr = call SubAMSend.getPayload(&packet, new_payload_len +
					sizeof(nx_struct reTrickle_header) +
					sizeof(nx_struct reTrickle_footer));

	nx_struct reTrickle_header* hdr = (nx_struct reTrickle_header*) ptr;
//	nx_struct reTrickle_footer* fdr = (nx_struct reTrickle_footer*) ptr + 
//				packet_len + sizeof(nx_struct reTrickle_header);
	ptr += sizeof(nx_struct reTrickle_header);

	call Param.get(DELAY, &delay, sizeof(delay));
	call SendTimer.startPeriodic(delay);

	packet_len = new_payload_len;

	memcpy(ptr, new_payload, new_payload_len);
	hdr->crc = (nx_uint16_t) crc16(0, ptr, packet_len);
	send_message();
}

bool same_packet(void *in_payload, uint8_t in_len) {
	uint8_t *ptr = call SubAMSend.getPayload(&packet, in_len +
					sizeof(nx_struct reTrickle_header) +
					sizeof(nx_struct reTrickle_footer));
	ptr += sizeof(nx_struct reTrickle_header);
	return ((in_len == packet_len) && !(memcmp(in_payload, ptr, in_len)));
}

command error_t SplitControl.start() {
	busy = FALSE;
	signal_send_done = FALSE;

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
	//printf("[%u] reTrickle fired\n", process);
#endif

	call Param.get(SUPPRESS, &suppress, sizeof(suppress));

	if (receive_same_packet < suppress) {
		send_message();
	}
	receive_same_packet = 0;
	return;
}

task void finish() {
	call SendTimer.stop();
	if ( signal_send_done ) {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] reTrickle signal sendDone\n", process);
#endif
		signal AMSend.sendDone(&packet, SUCCESS);
		signal_send_done = FALSE;
	}
}

async event void FinishTimer.fired() {
	post finish();
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	uint32_t now = call FinishTimer.getNow();
	uint8_t *ptr = call SubAMSend.getPayload(msg, len +
					sizeof(nx_struct reTrickle_header) +
					sizeof(nx_struct reTrickle_footer));
	ptr += sizeof(nx_struct reTrickle_header);
	signal_send_done = TRUE;
	if (same_packet(ptr, len)) {
		if (call FinishTimer.isRunning()) {
			return SUCCESS;
		}
		start_finish_timer( now, MILLI_2_32KHZ(3 * delay) );
		make_copy(ptr, len);
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] reTrickle re-sends the same version of payload\n", process);
#endif
		return SUCCESS;	
	}

	start_finish_timer( now, MILLI_2_32KHZ(repeat * delay) );
	make_copy(ptr, len);

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] reTrickle sends new version of payload\n", process);
#endif

	return SUCCESS;
}

command error_t AMSend.cancel(message_t* msg) {
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	return (call SubAMSend.maxPayloadLength() -
			sizeof(nx_struct reTrickle_header) -
			sizeof(nx_struct reTrickle_footer));
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr;
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, len + 
				sizeof(nx_struct reTrickle_header) +
				sizeof(nx_struct reTrickle_footer));
	return (void*) (ptr + sizeof(nx_struct reTrickle_header));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t in_len) {
	uint8_t *in_payload = (uint8_t*) payload;
	nx_struct reTrickle_header *in_hdr = (nx_struct reTrickle_header*) payload;
	nx_struct reTrickle_footer *in_fdr;
	uint32_t sender_time_left;

	/* At the moment of receive, how much time was left for receiver */
	uint32_t receiver_time_left = 0;

	if (call FinishTimer.isRunning()) {
		receiver_time_left = call FinishTimer.getAlarm() - call SubPacketTimeStamp32khz.timestamp(msg);
	}

	in_len -= (sizeof(nx_struct reTrickle_header) + sizeof(nx_struct reTrickle_footer));
	in_payload += sizeof(nx_struct reTrickle_header);
	in_fdr = (nx_struct reTrickle_footer*) (in_payload + in_len);

	if (in_hdr->crc != (nx_uint16_t) crc16(0, in_payload, in_len)) {
		return msg;
	}

	/* Compare everything with respect to the moment when the message was received */
	sender_time_left = in_hdr->left + in_fdr->offset;	/* how much time left on sender */

	if (same_packet(in_payload, in_len)) {
		if (call FinishTimer.isRunning()) {
			receive_same_packet++;
			printf("[%u] reTrickle receive %lu vs %lu\n", process, receiver_time_left, sender_time_left);
			if (receiver_time_left > sender_time_left) {
				start_finish_timer( call SubPacketTimeStamp32khz.timestamp(msg), sender_time_left);
				printf("[%u] reTrickle sender adjusted clock r:%lu > s:%lu\n", process, receiver_time_left, sender_time_left);
			}
		}
                return msg;
        }

	start_finish_timer( call SubPacketTimeStamp32khz.timestamp(msg), sender_time_left);
	make_copy(in_payload, in_len);

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
	return call SubPacket.payloadLength(msg);
}

command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
	return call SubPacket.setPayloadLength(msg, len);
}

command uint8_t Packet.maxPayloadLength() {
	return call SubPacket.maxPayloadLength();
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	return call SubPacket.getPayload(msg, len);
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
