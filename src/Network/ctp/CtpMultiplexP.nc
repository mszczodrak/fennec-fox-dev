module CtpMultiplexP {
provides interface AMSend[uint8_t id];
provides interface Receive[uint8_t id];
provides interface Receive as Snoop[uint8_t id];

uses interface AMSend as MacAMSend;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;


uses interface Send as QueueSend[uint8_t sid];

provides interface AMSend as SubQueueAMSend[uint8_t id];

}
implementation {

ctp_routing_header_t* getRoutingHeader(message_t* ONE m) {
	return (ctp_routing_header_t*)call MacAMSend.getPayload(m,
					call MacAMSend.maxPayloadLength());
}

ctp_data_header_t* getDataHeader(message_t* ONE m) {
	return (ctp_data_header_t*)call MacAMSend.getPayload(m,
					call MacAMSend.maxPayloadLength());
}


command error_t AMSend.send[uint8_t id](am_addr_t dest, message_t* m, uint8_t len) {
	call MacAMPacket.setDestination(m, dest);
	getRoutingHeader(m)->am = id;
	switch(id) {
	case AM_CTP_ROUTING:
		call MacAMPacket.setType(m, CTP_ROUTING_BEACON);
		return call QueueSend.send[CTP_ROUTING_BEACON](m, len);

	case AM_CTP_DATA:
		call MacAMPacket.setType(m, CTP_DATA_MSG);
		return call QueueSend.send[CTP_DATA_MSG](m, len);

	default:
		return FAIL;
	}
}

command error_t AMSend.cancel[uint8_t id](message_t* m) {
	getRoutingHeader(m)->am = id;
	switch(id) {
	case AM_CTP_ROUTING:
		call MacAMPacket.setType(m, CTP_ROUTING_BEACON);
		return call QueueSend.cancel[CTP_ROUTING_BEACON](m);

	case AM_CTP_DATA:
		call MacAMPacket.setType(m, CTP_DATA_MSG);
		return call QueueSend.cancel[CTP_DATA_MSG](m);

	default:
		return FAIL;
	}
}

command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
	switch(id) {
	case AM_CTP_ROUTING:
		return call QueueSend.maxPayloadLength[CTP_ROUTING_BEACON]();

	case AM_CTP_DATA:
		return call QueueSend.maxPayloadLength[CTP_DATA_MSG]();

	default:
		return 0;
	}
}

command void* AMSend.getPayload[uint8_t id](message_t* m, uint8_t len) {
	switch(id) {
	case AM_CTP_ROUTING:
		return call QueueSend.getPayload[CTP_ROUTING_BEACON](m, len);

	case AM_CTP_DATA:
		return call QueueSend.getPayload[CTP_DATA_MSG](m, len);

	default:
		return NULL;
	}
}

event void QueueSend.sendDone[uint8_t sid](message_t* m, error_t err) {
	switch(sid) {
	case CTP_ROUTING_BEACON:
		call MacAMPacket.setType(m, AM_CTP_ROUTING);
		signal AMSend.sendDone[AM_CTP_ROUTING](m, err);
		break;

	case CTP_DATA_MSG:
		call MacAMPacket.setType(m, AM_CTP_DATA);
		signal AMSend.sendDone[AM_CTP_DATA](m, err);
		break;

	default:
	}
}

event message_t* MacReceive.receive(message_t *m, void *payload, uint8_t len) {
	switch(getRoutingHeader(m)->am) {
	case AM_CTP_ROUTING:
		call MacAMPacket.setType(m, AM_CTP_ROUTING);
		return signal Receive.receive[AM_CTP_ROUTING](m, payload, len);

	case AM_CTP_DATA:
		call MacAMPacket.setType(m, AM_CTP_DATA);
		return signal Receive.receive[AM_CTP_DATA](m, payload, len);

	default:
		return m;
	}
}

event message_t* MacSnoop.receive(message_t *m, void *payload, uint8_t len) {
	switch(getRoutingHeader(m)->am) {
	case AM_CTP_ROUTING:
		call MacAMPacket.setType(m, AM_CTP_ROUTING);
		return signal Snoop.receive[AM_CTP_ROUTING](m, payload, len);

	case AM_CTP_DATA:
		call MacAMPacket.setType(m, AM_CTP_DATA);
		return signal Snoop.receive[AM_CTP_DATA](m, payload, len);

	default:
		return m;
	}
}

event void MacAMSend.sendDone(message_t* m, error_t err) {
	switch(getRoutingHeader(m)->am) {
	case AM_CTP_ROUTING:
		call MacAMPacket.setType(m, CTP_ROUTING_BEACON);
		signal SubQueueAMSend.sendDone[CTP_ROUTING_BEACON](m, err);
		break;

	case AM_CTP_DATA:
		call MacAMPacket.setType(m, CTP_DATA_MSG);
		signal SubQueueAMSend.sendDone[CTP_DATA_MSG](m, err);
		break;

	default:
	}
}

command error_t SubQueueAMSend.send[uint8_t id](am_addr_t dest, message_t* m, uint8_t len) {
	return call MacAMSend.send(dest, m, len);
}

command error_t SubQueueAMSend.cancel[uint8_t id](message_t* m) {
	return call MacAMSend.cancel(m);
}

command uint8_t SubQueueAMSend.maxPayloadLength[uint8_t id]() {
	return call MacAMSend.maxPayloadLength();
}

command void* SubQueueAMSend.getPayload[uint8_t id](message_t* m, uint8_t len) {
	return call MacAMSend.getPayload(m, len);
}

default event message_t* Snoop.receive[uint8_t id](message_t* m, void* payload, uint8_t len) { return m; }
default event message_t* Receive.receive[uint8_t id](message_t* m, void* payload, uint8_t len) { return m; }
default event void AMSend.sendDone[uint8_t id](message_t* m, error_t error) {}

}

