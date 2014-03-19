#include <Fennec.h>
#include "csma.h"

generic module csmaP(process_t process) @safe() {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;

provides interface Packet as MacPacket;
provides interface AMPacket as MacAMPacket;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmaParams;
uses interface BareSend as SubSend;
uses interface BareReceive as Receive;
uses interface SplitControl as SubSplitControl;
uses interface RadioPacket as SubPacket;

/*
uses interface RadioPacket;

uses interface SplitControl as RadioControl;

//uses interface RadioConfig;
uses interface RadioPower;
uses interface Read<uint16_t> as ReadRssi;
uses interface Resource as RadioResource;

uses interface RadioReceive;

uses interface Random;
uses interface ReceiveIndicator as EnergyIndicator;
uses interface ReceiveIndicator as ByteIndicator;
uses interface ReceiveIndicator as PacketIndicator;

uses interface LinkPacketMetadata as RadioLinkPacketMetadata;
uses interface RadioCCA;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface Timer<TMilli>;
*/


}

implementation {

/*
csma_header_t* getHeader(message_t *m) {
	uint8_t *p = (uint8_t*)(m->data);
	return (csma_header_t*)(p + call RadioPacket.headerLength(m));
}
*/

command error_t SplitControl.start() {
	dbg("Mac", "[%d] csma SplitControl.start()", process);
	return call SubSplitControl.start();
}


command error_t SplitControl.stop() {
	dbg("Mac", "[%d] csma SplitControl.stop()", process);
	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t err) {
	signal SplitControl.startDone(err);
}

event void SubSplitControl.stopDone(error_t err) {
	signal SplitControl.stopDone(err);
}


command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
                if( len > call MacPacket.maxPayloadLength() )
                        return EINVAL;

                if( call Config.checkFrame(msg) != SUCCESS )
                        return FAIL;

                call MacPacket.setPayloadLength(msg, len);
                call MacAMPacket.setSource(msg, call AMPacket.address());
                call MacAMPacket.setGroup(msg, call AMPacket.localGroup());
                call MacAMPacket.setType(msg, id);
                call MacAMPacket.setDestination(msg, addr);

                signal SendNotifier.aboutToSend[id](addr, msg);

                return call SubSend.send(msg);




	return call SubSend.send(msg);
}

command error_t MacAMSend.cancel(message_t* msg) {
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

command am_addr_t MacAMPacket.address() {
	return TOS_NODE_ID;
}

command am_addr_t MacAMPacket.destination(message_t* amsg) {
	return SubAM
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


async event void BareSend.sendDone(message_t *msg, error_t error) {
	dbg("Mac", "[%d] csma MacAMSend.sendDone(0x%1x, %d )", process, msg, error);
	signal MacAMSend.sendDone(msg, error);
}

event void Timer.fired() {
	if ((m_state == S_BEGIN_TRANSMIT) || (m_state == S_LOAD)) {
		dbg("Mac", "[%d] csma Timer.fired() - FAIL at %d state", process, m_state);
		sendErr = FAIL;
		post sendDone_task();
	}
}

async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call RadioLinkPacketMetadata.highChannelQuality(msg);
}



}

