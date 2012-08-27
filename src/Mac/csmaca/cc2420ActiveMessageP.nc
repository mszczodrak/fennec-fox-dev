#include <Fennec.h>
#include <Ieee154.h> 
#include "CC2420.h"
#include "csmacaMac.h"

module cc2420ActiveMessageP @safe() {
  provides {
    interface AMSend;
    interface Receive;
    interface Receive as Snoop;
    interface AMPacket;
    interface Packet;
  }

  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface CC2420Packet;
    interface CC2420PacketBody;
//    interface CC2420Config;
    interface ActiveMessageAddress;

    interface Resource as RadioResource;
    interface Leds;
  }
}
implementation {
  uint16_t pending_length;
  message_t * ONE_NOK pending_message = NULL;

  /***************** Resource event  ****************/
  event void RadioResource.granted() {
    uint8_t rc;

    rc = call SubSend.send( pending_message, pending_length );
    if (rc != SUCCESS) {
      call RadioResource.release();
      signal AMSend.sendDone( pending_message, rc );
    }
  }

  /***************** AMSend Commands ****************/
  command error_t AMSend.send(am_addr_t addr,
					  message_t* msg,
					  uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );
    msg->crc = 0;
    msg->rssi = 0;
    msg->lqi = 0;
   
    if (len > call Packet.maxPayloadLength()) {
      return ESIZE;
    }
    
    //header->type = id;
    header->dest = addr;
    //header->destpan = call CC2420Config.getPanAddr();
    //header->destpan = signal Mgmt.currentStateId();
    //header->destpan = msg->conf;
    header->src = call AMPacket.address();
    header->fcf |= ( 1 << IEEE154_FCF_INTRAPAN ) |
      ( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
      ( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;
    header->length = len + CC2420_SIZE;
    
    if (call RadioResource.immediateRequest() == SUCCESS) {
      error_t rc;
      
      rc = call SubSend.send( msg, len );
      if (rc != SUCCESS) {
        call RadioResource.release();
      }

      return rc;
    } else {
      pending_length  = len;
      pending_message = msg;
      return call RadioResource.request();
    }
  }

  command error_t AMSend.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t AMSend.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload(message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  /***************** AMPacket Commands ****************/
  command am_addr_t AMPacket.address() {
    return call ActiveMessageAddress.amAddress();
  }
 
  command am_addr_t AMPacket.destination(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->dest;
  }
 
  command am_addr_t AMPacket.source(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->dest = addr;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->src = addr;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t type) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->type = type;
  }
  
  command am_group_t AMPacket.group(message_t* amsg) {
    return (call CC2420PacketBody.getHeader(amsg))->destpan;
  }

  command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(amsg))->destpan = grp;
  }

  command am_group_t AMPacket.localGroup() {
    return 0;
//    return call CC2420Config.getPanAddr();
  }
  

  /***************** Packet Commands ****************/
  command void Packet.clear(message_t* msg) {
    memset(call CC2420PacketBody.getHeader(msg), 0x0, sizeof(cc2420_header_t));
    memset(call CC2420PacketBody.getMetadata(msg), 0x0, sizeof(cc2420_metadata_t));
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }

  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    call RadioResource.release();
    signal AMSend.sendDone(msg, result);
  }

  
  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    cc2420_metadata_t *meta = call CC2420PacketBody.getMetadata(msg);
    msg->conf = call AMPacket.group(msg); 
    msg->rssi = meta->rssi; 
    msg->lqi = meta->lqi;
    msg->crc = meta->crc;

    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive(msg, payload, len);
    }
    else {
      return signal Snoop.receive(msg, payload, len);
    }
  }
  

  /***************** ActiveMessageAddress Events ****************/
  async event void ActiveMessageAddress.changed() {
  }
  
  
  /***************** Defaults ****************/
  default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event message_t* Snoop.receive(message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event void AMSend.sendDone(message_t* msg, error_t err) {
    call RadioResource.release();
  }

}
