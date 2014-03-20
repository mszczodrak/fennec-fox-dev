generic module CtpActiveMessageP() {
provides interface SplitControl;
provides interface AMSend[am_id_t id];
provides interface Receive[am_id_t id];
provides interface Receive as Snoop[am_id_t id];
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {

uint8_t getCtpType(message_t* msg) {
	uint8_t t;
	uint8_t *ptr = (uint8_t*)call MacAMSend.getPayload(msg, sizeof(2));
	if (ptr == NULL) {
		dbg("Network-Detail", "CTP CtpActiveMessageP getCtpType(0x%1x) - got NULL", msg);
		return 0;
	}
	ptr++;
	t = *ptr;
	return t;
}

void do_sendDone(message_t *msg, error_t error) {
	dbg("Network-Detail", "CTP CtpActiveMessageP do_sendDone(0x%1x, %d) - type %d",
				msg, error, getCtpType(msg));
	signal AMSend.sendDone[getCtpType(msg)](msg, error);
}

message_t* do_receive(message_t *msg, void *payload, uint8_t len) {
	dbg("Network-Detail", "CTP CtpActiveMessageP do_receive(0x%1x, 0x%1x, %d) - type %d",
				msg, payload, len, getCtpType(msg));
	return signal Receive.receive[getCtpType(msg)](msg, (void*)(((uint8_t*)payload)), len);
}

message_t* do_snoop(message_t *msg, void *payload, uint8_t len) {
	dbg("Network-Detail", "CTP CtpActiveMessageP do_snoop(0x%1x, 0x%1x, %d) - type %d",
				msg, payload, len, getCtpType(msg));
	return signal Snoop.receive[getCtpType(msg)](msg, (void*)(((uint8_t*)payload)), len);
}

command error_t SplitControl.start() { return SUCCESS; }
command error_t SplitControl.stop() { return SUCCESS; }


command void* AMSend.getPayload[am_id_t id](message_t *msg, uint8_t len) {
	return call MacAMSend.getPayload(msg, len);
}

command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t *msg, uint8_t len) {
	return call MacAMSend.send(addr, msg, len);
}

command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
	dbg("Network-Detail", "CTP ctpActiveMessageP AMSend.maxPayloadLength()");
	return call MacAMSend.maxPayloadLength();
}

command error_t AMSend.cancel[am_id_t id](message_t *msg) {
	return call MacAMSend.cancel(msg);
}

command am_addr_t AMPacket.address() {
	return call MacAMPacket.address();
}

command am_addr_t AMPacket.destination(message_t* amsg) {
	return call MacAMPacket.destination(amsg);
}

command am_addr_t AMPacket.source(message_t* amsg) {
	return call MacAMPacket.source(amsg);
}

command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setDestination(amsg, addr);
}

command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setSource(amsg, addr);
}

command bool AMPacket.isForMe(message_t* amsg) {
	return call MacAMPacket.isForMe(amsg);
}

command am_id_t AMPacket.type(message_t* amsg) {
	return getCtpType(amsg);
}

command void AMPacket.setType(message_t* amsg, am_id_t t) {
//    return call MacAMPacket.setType(amsg, t);
}

command am_group_t AMPacket.group(message_t* amsg) {
	return call MacAMPacket.group(amsg);
}

command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call MacAMPacket.setGroup(amsg, grp);
}

command am_group_t AMPacket.localGroup() {
	return call MacAMPacket.localGroup();
}

command void Packet.clear(message_t* msg) {
	return call MacPacket.clear(msg);
}

command uint8_t Packet.payloadLength(message_t* msg) {
	return call MacPacket.payloadLength(msg);
}

command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
	return call MacPacket.setPayloadLength(msg, len);
}

command uint8_t Packet.maxPayloadLength() {
	dbg("Network-Detail", "CTP %s ctpActiveMessageP Packet.maxPayloadLength()", __FUNCTION__);
	return call MacPacket.maxPayloadLength();
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	return call MacPacket.getPayload(msg, len);
}

async command error_t PacketAcknowledgements.requestAck( message_t* msg ) {
	return call MacPacketAcknowledgements.requestAck(msg);
}

async command error_t PacketAcknowledgements.noAck( message_t* msg ) {
	return call MacPacketAcknowledgements.noAck(msg);
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return call MacPacketAcknowledgements.wasAcked(msg);
}

event void MacAMSend.sendDone(message_t *msg, error_t error) {
	do_sendDone(msg, error);
}

event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	//dbgs(F_NETWORK, S_NONE, DBGS_GOT_RECEIVE, 0, 0);
	return do_receive(msg, payload, len);
}

event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return do_snoop(msg, payload, len);
}

default event message_t* Receive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
	return msg;
}

default event message_t* Snoop.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
	return msg;
}

}
