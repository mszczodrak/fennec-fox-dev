#include <Fennec.h>
#include "csma.h"

generic module csmaP(process_t process) @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmaParams;
uses interface RadioBuffer;
uses interface RadioPacket;
uses interface RadioSend;

uses interface SplitControl as RadioControl;

uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface RadioReceive;

uses interface Random;
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as PacketIndicator;

uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;
uses interface RadioCCA;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface Timer<TMilli>;
}

implementation {

uint8_t status = S_STOPPED;
norace message_t * ONE_NOK m_msg;
norace message_t * ONE_NOK r_msg;
norace message_t * ONE_NOK r_msg_ptr;
norace uint8_t m_state = S_STOPPED;

norace error_t sendErr = SUCCESS;

norace message_t receiveQueueData[csma_RECEIVE_QUEUE_SIZE];
norace message_t* receiveQueue[csma_RECEIVE_QUEUE_SIZE];

norace uint8_t receiveQueueHead;
norace uint8_t receiveQueueSize;

task void startDone_task();
task void stopDone_task();
task void sendDone_task();

task void startDone_task() {
	uint8_t i;
	for(i = 0; i < csma_RECEIVE_QUEUE_SIZE; ++i) {
		receiveQueue[i] = receiveQueueData + i;
	}
	m_state = S_STARTED;
	signal SplitControl.startDone(SUCCESS);
}

task void stopDone_task() {
	m_state = S_STOPPED;
	signal SplitControl.stopDone(SUCCESS);
}

csma_header_t* getHeader(message_t *m) {
	uint8_t *p = (uint8_t*)(m->data);
	return (csma_header_t*)(p + call RadioPacket.headerLength(m));
}



command error_t SplitControl.start() {
	dbg("Mac", "[%d] csma SplitControl.start()", process);
	post startDone_task();
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("Mac", "[%d] csma SplitControl.stop()", process);
	post stopDone_task();
	return SUCCESS;
}



event void RadioControl.startDone(error_t err) {
	dbg("Mac", "[%d] csma RadioControl.startDone(%d)", process, err);
}


event void RadioControl.stopDone(error_t err) {
	dbg("Mac", "[%d] csma RadioControl.stopDone(%d)", process, err);
} 


command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	csma_header_t* header;

	dbg("Mac", "[%d] csma MacAMSend.send(%d, 0x%1x, %d )",
		process, addr, msg, len);

	header = getHeader(msg);

	getMetadata(msg)->crc = 0;
	getMetadata(msg)->rssi = 0;
	getMetadata(msg)->lqi = 0;
	getMetadata(msg)->ack = 1;

	if (len > call MacPacket.maxPayloadLength()) {
		dbg("Mac", "[%d] csma len > maxPayloadLength)", process);
		return ESIZE;
	}

	if ( m_state != S_STARTED ) {
		dbg("Mac", "[%d] csma state != S_STARTED, but %d", process, m_state);
		return FAIL;
	}

	header->dest = addr;
	header->src = call MacAMPacket.address();
	header->fcf |= ( 1 << IEEE154_FCF_INTRAPAN ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
		( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;

	call MacPacket.setPayloadLength(msg, len);

	if (header->fcf & 1 << IEEE154_FCF_ACK_REQ) {
		header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	}

	m_msg = msg;

	header->fcf &= ((1 << IEEE154_FCF_ACK_REQ) |
		(0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
		(0x3 << IEEE154_FCF_DEST_ADDR_MODE));
	header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
		( 1 << IEEE154_FCF_INTRAPAN ) );

	m_state = S_LOAD;

	call Timer.startOneShot(csma_TIMER_DELAY);
	if (call RadioBuffer.load(m_msg) != SUCCESS) {
		call Timer.stop();
		m_state = S_STARTED;
		return FAIL;
	}
	return SUCCESS;
}

command error_t MacAMSend.cancel(message_t* msg) {
	dbg("Mac", "[%d] csma MacAMSend.cancel(0x%1x)", process, msg);
	if (m_state == S_BEGIN_TRANSMIT) {
		m_state = S_STARTED;
	}
}

command uint8_t MacAMSend.maxPayloadLength() {
	dbg("Mac", "[%d] csma MacAMSend.maxPayloadLength()", process);
	return call MacPacket.maxPayloadLength();
}

command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac", "[%d] csma MacAMSend.getpayload(0x%1x, %d )",
		process, msg, len);
	return call MacPacket.getPayload(msg, len);
}

async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
	csma_header_t* header = getHeader(p_msg);
	header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
	csma_header_t* header = getHeader(p_msg);
	header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
	return SUCCESS;
}

async command bool MacPacketAcknowledgements.wasAcked( message_t* p_msg ) {
	metadata_t* metadata = (metadata_t*) p_msg->metadata;
	return metadata->ack;
}

event void RadioConfig.syncDone(error_t error) {
}

async event void RadioPower.startVRegDone() {
}

async event void RadioPower.startOscillatorDone() {
}

event void ReadRssi.readDone(error_t error, uint16_t rssi) {
}

event void RadioResource.granted() {
}

command am_addr_t MacAMPacket.address() {
	return TOS_NODE_ID;
}

command am_addr_t MacAMPacket.destination(message_t* amsg) {
	return getHeader(amsg)->dest;
}

command am_addr_t MacAMPacket.source(message_t* amsg) {
	return getHeader(amsg)->src;
}

command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	getHeader(amsg)->dest = addr;
}

command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	getHeader(amsg)->src = addr;
}

command bool MacAMPacket.isForMe(message_t* amsg) {
	return (call MacAMPacket.destination(amsg) == call MacAMPacket.address() ||
		call MacAMPacket.destination(amsg) == AM_BROADCAST_ADDR);
}

command am_id_t MacAMPacket.type(message_t* amsg) {
	return UNKNOWN;
}

command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
}

command am_group_t MacAMPacket.group(message_t* amsg) {
	return getHeader(amsg)->destpan;
}

command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	getHeader(amsg)->destpan = grp;
	// Overridden intentionally when we send()
}

command am_group_t MacAMPacket.localGroup() {
	return 0;
//    return call CC2420Config.getPanAddr();
}


command void MacPacket.clear(message_t* msg) {
	call RadioPacket.clear(msg);
}

command uint8_t MacPacket.payloadLength(message_t* msg) {
	dbg("Mac", "[%d] csma MacPacket.payloadLength( 0x%1x )",
			process, msg);
	return call RadioPacket.payloadLength(msg) - sizeof(csma_header_t);
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
	dbg("Mac", "[%d] csma MacPacket.setPayloadLength( 0x%1x, %d )",
			process, msg, len);
	call RadioPacket.setPayloadLength(msg, len + sizeof(csma_header_t));
}

command uint8_t MacPacket.maxPayloadLength() {
	dbg("Mac", "[%d] csma MacPacket.maxPayloadLength()",
			process);
	return call RadioPacket.maxPayloadLength() - sizeof(csma_header_t);
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	dbg("Mac", "[%d] csma MacPacket.getPayload( 0x%1x, %d )",
			process, msg, len);
	if (len <= call MacPacket.maxPayloadLength()) {
		uint8_t *p = (uint8_t*) getHeader(msg);
		return (p + sizeof(csma_header_t));
	} else {
		return NULL;
	}
}

task void sendDone_task() {
	call Timer.stop();
	if (m_state != S_STOPPED) {
		m_state = S_STARTED;
	}
	signal MacAMSend.sendDone( m_msg, sendErr );
}

task void deliverTask() {
        // get rid of as many messages as possible without interveining tasks
        message_t* msg;
        uint8_t *p;
	uint8_t len;

	atomic {
		if( receiveQueueSize == 0 ) {
			return;
		}

		msg = receiveQueue[receiveQueueHead];
		p = (uint8_t*)(msg->data);
		p += (call RadioPacket.headerLength(msg) + sizeof(csma_header_t));
		len = (call RadioPacket.payloadLength(msg) - sizeof(csma_header_t));
	}

	if (call MacAMPacket.isForMe(msg)) {
		dbg("Mac", "[%d] csma MacReceive.receive(0x%1x, 0x%1x, %d )",
			process, msg, p, len);
		msg = signal MacReceive.receive(msg, p, len);
	} else {
		dbg("Mac", "csma MacSnoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, p, len);
		msg = signal MacSnoop.receive(msg, p, len);
	}

	atomic {
		call RadioPacket.clear(msg);
		receiveQueue[receiveQueueHead] = msg;
		if( ++receiveQueueHead >= csma_RECEIVE_QUEUE_SIZE )
			receiveQueueHead = 0;

		--receiveQueueSize;
	}
	post deliverTask();
}



async event message_t* RadioReceive.receive(message_t* msg) {
	message_t *m;
	if(!(getMetadata(msg))->crc) {
		dbg("Mac", "[%d] csma RadioReceive.receive did not pass CRC", process);
		return msg;
	}

	dbg("Mac", "[%d] csma RadioReceive.receive(0x%1x)", process, msg);
	atomic {
		if( receiveQueueSize >= csma_RECEIVE_QUEUE_SIZE ) {
			m = msg;
		} else {
			uint8_t idx = receiveQueueHead + receiveQueueSize;
			if( idx >= csma_RECEIVE_QUEUE_SIZE )
				idx -= csma_RECEIVE_QUEUE_SIZE;

			m = receiveQueue[idx];
			receiveQueue[idx] = msg;

			++receiveQueueSize;
			post deliverTask();
		}
	}
	return m;
}

async event bool RadioReceive.header(message_t* msg) {
	return receiveQueueSize < csma_RECEIVE_QUEUE_SIZE;
	//return TRUE;
}

task void transmit() {
	m_state = S_BEGIN_TRANSMIT;
	call Timer.startOneShot(csma_TIMER_DELAY);
	sendErr = call RadioSend.send(m_msg, 0);
	if (sendErr != SUCCESS) {
		dbg("Mac", "[%d] csma RadioSend.send(0x%1x, %d ) - FAIL", process, m_msg, sendErr);
		post sendDone_task();
	} else {
		dbg("Mac", "[%d] csma RadioSend.send(0x%1x, %d )", process, m_msg, sendErr);
	}
}

async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
	if (m_state != S_LOAD) {
		return;
	}

	if (error != SUCCESS) {
		sendErr = error;
		post sendDone_task();
		dbg("Mac", "[%d] csma RadioBuffer.loadDone(0x%1x, %d ) - FAIL", process, msg, error);
	}

	post transmit();
}


async event void RadioSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "[%d] csma MacAMSend.sendDone(0x%1x, %d )", process, msg, error);
	atomic sendErr = error;
	post sendDone_task();
}

event void Timer.fired() {
	if ((m_state == S_BEGIN_TRANSMIT) || (m_state == S_LOAD)) {
		dbg("Mac", "[%d] csma Timer.fired() - FAIL at %d state", process, m_state);
		sendErr = FAIL;
		post sendDone_task();
	}
}

event void RadioState.done() {}


async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call RadioLinkPacketMetadata.highChannelQuality(msg);
}

async event void RadioSend.ready() {

}

async event void RadioCCA.done(error_t err) {

}



}

