generic module SimActiveMessageP() {
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;

  uses interface AMSend;
  uses interface Receive;
  uses interface Receive as Snoop;
  uses interface AMPacket;
}

implementation {

  command error_t RadioAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    call AMPacket.setGroup(msg, msg->conf);
    dbg("Radio", "Radio sends msg on state %d\n", msg->conf);
    return call AMSend.send(addr, msg, len);
  }

  command error_t RadioAMSend.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t RadioAMSend.maxPayloadLength() {
    return call AMSend.maxPayloadLength();
  }

  command void* RadioAMSend.getPayload(message_t* msg, uint8_t len) {
    return call AMSend.getPayload(msg, len);
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
    signal RadioAMSend.sendDone(msg, error);
  }

  event message_t* Receive.receive(message_t *msg, void* payload, uint8_t len) {
    msg->conf = call AMPacket.group(msg);
    dbg("Radio", "Radio receives msg on state %d\n", msg->conf);
    return signal RadioReceive.receive(msg, payload, len);
  }

  event message_t* Snoop.receive(message_t *msg, void* payload, uint8_t len) {
    msg->conf = call AMPacket.group(msg);
    return signal RadioSnoop.receive(msg, payload, len);
  }


}
