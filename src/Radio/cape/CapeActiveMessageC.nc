#include <AM.h>

module CapeActiveMessageC {
  provides {
    
    interface AMSend[am_id_t id];
    interface Receive;

    interface Packet;
    interface AMPacket;
  }
  uses {
    interface TossimPacketModel as Model;
  }
}
implementation {

  message_t buffer;
  message_t* bufferPointer = &buffer;
  
  tossim_header_t* getHeader(message_t* amsg) {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }

  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* amsg,
					  uint8_t len) {
    error_t err;
//    tossim_header_t* header = getHeader(amsg);
//    dbg("AM", "AM: Sending packet (id=%hhu, len=%hhu) to %hu\n", id, len, addr);
//    header->type = id;
//    header->dest = addr;
//    header->src = call AMPacket.address();
//    header->length = len;
//    err = call Model.send((int)addr, amsg, len + sizeof(tossim_header_t) + sizeof(tossim_footer_t));
    err = call Model.send(addr, amsg, len);
    return err;
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call Model.cancel(msg);
  }
  
  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  event void Model.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  /* Receiving a packet */

  event void Model.receive(message_t* msg) {
    uint8_t len;
    void* payload;

    dbg("TossimActiveMessageC", "TossimActiveMessageC Model.receive()");

    memcpy(bufferPointer, msg, sizeof(message_t));
    len = call Packet.payloadLength(bufferPointer);
    payload = call Packet.getPayload(bufferPointer, call Packet.maxPayloadLength());

    dbg("AM", "Received active message (%p) of type %hhu and length %hhu for me @ %s.", bufferPointer, call AMPacket.type(bufferPointer), len, sim_time_string());
    bufferPointer = signal Receive.receive(bufferPointer, payload, len);
  }

  event bool Model.shouldAck(message_t* msg) {
/*
    tossim_header_t* header = getHeader(msg);
    if (header->dest == call amAddress()) {
      dbg("Acks", "Received packet addressed to me so ack it\n");
      return TRUE;
    }
*/
    return FALSE;
  }
  
  command am_addr_t AMPacket.address() {
    return TOS_NODE_ID;
  }
 
  command am_addr_t AMPacket.destination(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->dest;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    tossim_header_t* header = getHeader(amsg);
    header->dest = addr;
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    tossim_header_t* header = getHeader(amsg);
    header->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t t) {
    tossim_header_t* header = getHeader(amsg);
    header->type = t;
  }
 
  command void Packet.clear(message_t* msg) {}
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return getHeader(msg)->length;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getHeader(msg)->length = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return msg->data;
    }
    else {
      return NULL;
    }
  }

  command am_group_t AMPacket.group(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->group;
  }
  
  command void AMPacket.setGroup(message_t* msg, am_group_t group) {
    tossim_header_t* header = getHeader(msg);
    header->group = group;
  }

  command am_group_t AMPacket.localGroup() {
    return TOS_AM_GROUP;
  }

 default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
   return;
 }

 default command error_t Model.send(int node, message_t* msg, uint8_t len) {
   return FAIL;
 }

 default command error_t Model.cancel(message_t* msg) {
   return FAIL;
 }

 void active_message_deliver_handle(sim_event_t* evt) {
   message_t* m = (message_t*)evt->data;
   dbg("Packet", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());
   signal Model.receive(m);
 }
 
 sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t) {
   sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
   evt->mote = node;
   evt->time = t;
   evt->handle = active_message_deliver_handle;
   evt->cleanup = sim_queue_cleanup_event;
   evt->cancelled = 0;
   evt->force = 0;
   evt->data = msg;
   return evt;
 }
 
 void active_message_deliver(int node, message_t* msg, sim_time_t t) @C() @spontaneous() {
   sim_event_t* evt = allocate_deliver_event(node, msg, t);
   sim_queue_insert(evt);
 }
 
}
