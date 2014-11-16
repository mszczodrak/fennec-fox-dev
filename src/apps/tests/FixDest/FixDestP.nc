#include <Fennec.h>
#include "FixDest.h"

#include "fix_dest.h"

generic module FixDestP(process_t process_id) {
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
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;
}

implementation {

uint16_t offset;

void setup_dest() {
	uint16_t addr = TOS_NODE_ID - offset;
	uint16_t dest = 0;
	if (addr < SET_DEST_NUMBER_OF_NODES) {
		dest = fixed_dest[addr];
	}
	call Param.set(DEST, &dest, sizeof(dest));
}

command error_t SplitControl.start() {
	call Param.get(OFFSET, &offset, sizeof(offset));
	setup_dest();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	setup_dest();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id) {

}

}
