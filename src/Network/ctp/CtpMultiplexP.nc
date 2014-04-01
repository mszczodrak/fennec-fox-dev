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

ctp_routing_header_t* getHeader(message_t* ONE m) {
	return (ctp_routing_header_t*)call MacAMSend.getPayload(m,
					call MacAMSend.maxPayloadLength());
}

void setOption(message_t *msg, ctp_options_t opt) {
	getHeader(msg)->options |= opt;
}

void clearOption(message_t *msg, ctp_options_t opt) {
	getHeader(msg)->options &= ~opt;
}

bool option(message_t *msg, ctp_options_t opt) {
	return ((getHeader(msg)->options & opt) == opt) ? TRUE : FALSE;
}

command error_t AMSend.send[uint8_t id](am_addr_t dest, message_t* msg, uint8_t len) {
	call MacAMPacket.setDestination(msg, dest);
	if (id == AM_CTP_ROUTING) {
		setOption(msg, CTP_ROUTING_BEACON);
		return call QueueSend.send[CTP_ROUTING_BEACON](msg, len);
	} else {
		return call QueueSend.send[CTP_DATA_MSG](msg, len);
	}
}

command error_t AMSend.cancel[uint8_t id](message_t* msg) {
	if (id == AM_CTP_ROUTING) {
		return call QueueSend.cancel[CTP_ROUTING_BEACON](msg);
	} else {
		return call QueueSend.cancel[CTP_DATA_MSG](msg);
	}
}

command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
	if (id == AM_CTP_ROUTING) {
		return call QueueSend.maxPayloadLength[CTP_ROUTING_BEACON]();
	} else {
		return call QueueSend.maxPayloadLength[CTP_DATA_MSG]();
	}
}

command void* AMSend.getPayload[uint8_t id](message_t* m, uint8_t len) {
	if (id == AM_CTP_ROUTING) {
		return call QueueSend.getPayload[CTP_ROUTING_BEACON](m, len);
	} else {
		return call QueueSend.getPayload[CTP_DATA_MSG](m, len);
	}
}

event void QueueSend.sendDone[uint8_t sid](message_t* m, error_t err) {
	if (sid == CTP_ROUTING_BEACON) {
		clearOption(m, CTP_ROUTING_BEACON);
		signal AMSend.sendDone[AM_CTP_ROUTING](m, err);
	} else {
		signal AMSend.sendDone[AM_CTP_DATA](m, err);
	}
}

event message_t* MacReceive.receive(message_t *m, void *payload, uint8_t len) {
	if (option(m, CTP_ROUTING_BEACON)) {
		clearOption(m, CTP_ROUTING_BEACON);
		return signal Receive.receive[AM_CTP_ROUTING](m, payload, len);
	} else {
		return signal Receive.receive[AM_CTP_DATA](m, payload, len);
	}
}

event message_t* MacSnoop.receive(message_t *m, void *payload, uint8_t len) {
	if (option(m, CTP_ROUTING_BEACON)) {
		clearOption(m, CTP_ROUTING_BEACON);
		return signal Snoop.receive[AM_CTP_ROUTING](m, payload, len);
	} else {
		return signal Snoop.receive[AM_CTP_DATA](m, payload, len);
	}
}

event void MacAMSend.sendDone(message_t* m, error_t err) {
	if (option(m, CTP_ROUTING_BEACON)) {
		//clearOption(m, CTP_ROUTING_BEACON);
		return signal SubQueueAMSend.sendDone[AM_CTP_ROUTING](m, err);
	} else {
		return signal SubQueueAMSend.sendDone[AM_CTP_DATA](m, err);
	}
}

command error_t SubQueueAMSend.send[uint8_t id](am_addr_t dest, message_t* msg, uint8_t len) {
	return call MacAMSend.send(dest, msg, len);
}

command error_t SubQueueAMSend.cancel[uint8_t id](message_t* msg) {
	return call MacAMSend.cancel(msg);
}

command uint8_t SubQueueAMSend.maxPayloadLength[uint8_t id]() {
	return call MacAMSend.maxPayloadLength();
}

command void* SubQueueAMSend.getPayload[uint8_t id](message_t* m, uint8_t len) {
	return call MacAMSend.getPayload(m, len);
}

default event message_t* Snoop.receive[uint8_t id](message_t* msg, void* payload, uint8_t len) { return msg; }
default event message_t* Receive.receive[uint8_t id](message_t* msg, void* payload, uint8_t len) { return msg; }
default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t error) {}

}

