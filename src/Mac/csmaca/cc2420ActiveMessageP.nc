#include <Fennec.h>
#include <Ieee154.h> 
#include "CC2420.h"
#include "csmacaMac.h"

module cc2420ActiveMessageP @safe() {
  provides {
    interface AMSend;
    interface Receive;
    interface Receive as Snoop;
  }

  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;

    interface Resource as RadioResource;
    interface Leds;
  }

  uses interface Packet as MacPacket;
  uses interface AMPacket as MacAMPacket;

  uses interface CC2420Packet;
  uses interface CC2420PacketBody;


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
   
    if (len > call MacPacket.maxPayloadLength()) {
      return ESIZE;
    }
    
    //header->type = id;
    header->dest = addr;
    //header->destpan = call CC2420Config.getPanAddr();
    //header->destpan = signal Mgmt.currentStateId();
    //header->destpan = msg->conf;
    header->src = call MacAMPacket.address();
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
    return call MacPacket.maxPayloadLength();
  }

  command void* AMSend.getPayload(message_t* m, uint8_t len) {
    return call MacPacket.getPayload(m, len);
  }

  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    call RadioResource.release();
    signal AMSend.sendDone(msg, result);
  }

  
  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    cc2420_metadata_t *meta = call CC2420PacketBody.getMetadata(msg);
    msg->conf = call MacAMPacket.group(msg); 
    msg->rssi = meta->rssi; 
    msg->lqi = meta->lqi;
    msg->crc = meta->crc;

    if (call MacAMPacket.isForMe(msg)) {
      return signal Receive.receive(msg, payload, len);
    }
    else {
      return signal Snoop.receive(msg, payload, len);
    }
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
