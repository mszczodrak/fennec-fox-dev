
#include <sim_radio.h>
#include <Fennec.h>

module CapePacketModelC { 

provides interface SplitControl as Control;
provides interface TossimPacketModel as Packet;
uses interface GainRadioModel;

}

implementation {

bool running = FALSE;
message_t* sending = NULL;
bool transmitting = FALSE;
uint8_t sendingLength = 0;
int destNode;
sim_event_t sendEvent;
  
message_t receiveBuffer;
  
task void startDoneTask() {
	running = TRUE;
	signal Control.startDone(SUCCESS);
}

task void stopDoneTask() {
	running = FALSE;
	signal Control.stopDone(SUCCESS);
}
  
command error_t Control.start() {
	sendEvent.cancelled = 1;
	dbg("TossimPacketModelC", "TossimPacketModelC: Control.start() called.\n");
	post startDoneTask();
	return SUCCESS;
}

command error_t Control.stop() {
	running = FALSE;
	dbg("TossimPacketModelC", "TossimPacketModelC: Control.stop() called.\n");
	post stopDoneTask();
	return SUCCESS;
}

task void sendDoneTask() {
	message_t* msg = sending;
	metadata_t* meta = getMetadata(msg);
	meta->ack = 0;
	meta->strength = 0;
	meta->time = 0;
	sending = FALSE;
	signal Packet.sendDone(msg, running? SUCCESS:EOFF);
}

command error_t Packet.cancel(message_t* msg) {
	return FAIL;
}

void start_radio();

command error_t Packet.send(int dest, message_t* msg, uint8_t len) {
	if (!running) {
		dbg("TossimPacketModelC", "TossimPacketModelC: Send.send() called, but not running!\n");
		return EOFF;
	}
	dbg("TossimPacketModelC", "TossimPacketModelC packet.send");
	if (sending != NULL) {
		return EBUSY;
	}
	sendingLength = len; 
	sending = msg;
	destNode = dest;
	start_radio();
	return SUCCESS;
}

void send_transmit(sim_event_t* evt);
void send_transmit_done(sim_event_t* evt);
  
void start_radio() {
	transmitting = TRUE;
	call GainRadioModel.setPendingTransmission();

	sendEvent.mote = sim_node();
	sendEvent.time = sim_time();
	sendEvent.force = 0;
	sendEvent.cancelled = 0;

	sendEvent.handle = send_transmit; /* could add delay */

	sendEvent.cleanup = sim_queue_cleanup_none;
	sim_queue_insert(&sendEvent);
}

//    call GainRadioModel.clearChannel()) {


void send_transmit(sim_event_t* evt) {
	sim_time_t duration;
	metadata_t* metadata = getMetadata(sending);

	duration = 8 * sendingLength;
	duration /= sim_radio_bits_per_symbol();
	duration += sim_radio_preamble_length();
    
	if (metadata->ack) {
		duration += sim_radio_ack_time();
	}
	duration *= (sim_ticks_per_sec() / sim_radio_symbols_per_sec());

	evt->time += duration;
	evt->handle = send_transmit_done;

	dbg("TossimPacketModelC", "PACKET: Broadcasting packet to everyone.\n");
	call GainRadioModel.putOnAirTo(destNode, sending, metadata->ack, evt->time, 0.0, 0.0);
	metadata->ack = 0;

	evt->time += (sim_radio_rxtx_delay() *  (sim_ticks_per_sec() / sim_radio_symbols_per_sec()));

	dbg("TossimPacketModelC", "PACKET: Send done at %llu.\n", evt->time);
	sim_queue_insert(evt);
}

void send_transmit_done(sim_event_t* evt) {
	message_t* rval = sending;
	sending = NULL;
	transmitting = FALSE;
	dbg("TossimPacketModelC", "PACKET: Signaling send done at %llu.\n", sim_time());
	signal Packet.sendDone(rval, running? SUCCESS:EOFF);
}

event void GainRadioModel.receive(message_t* msg) {
	if (running && !transmitting) {
		signal Packet.receive(msg);
	}
}

uint8_t error = 0;
  
event void GainRadioModel.acked(message_t* msg) {
	if (running) {
		metadata_t* metadata = getMetadata(sending);
		metadata->ack = 1;
		if (msg != sending) {
			error = 1;
			dbg("TossimPacketModelC", "Requested ack for 0x%x, but outgoing packet is 0x%x.\n", msg, sending);
		}
	}
}

event bool GainRadioModel.shouldAck(message_t* msg) {
	if (running && !transmitting) {
		return signal Packet.shouldAck(msg);
	} else {
		return FALSE;
	}
}
 
}
