/*
 *  CSMA/CA MAC module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Module: CSMA/CA MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "csmacaMac.h"

#include <Ieee154.h> 
#include "CC2420.h"
#include "csmacaMac.h"


module csmacaMacP @safe() {
  provides interface Mgmt;
  provides interface ModuleStatus as MacStatus;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;

  provides interface Packet as MacPacket;
  provides interface AMPacket as MacAMPacket;

  uses interface csmacaMacParams;

  uses interface SplitControl as RadioControl;
  uses interface ParametersCC2420;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;

  uses interface RadioConfig;
  uses interface RadioPower;
  uses interface Read<uint16_t> as ReadRssi;
  uses interface Resource as RadioResource;

  uses interface CC2420Packet;
  uses interface CC2420PacketBody;

  uses interface Send as SubSend;
  uses interface Receive as SubReceive;

  uses interface Resource as SubRadioResource;
}

implementation {

  uint8_t status = S_STOPPED;
  uint16_t pending_length;
  message_t * ONE_NOK pending_message = NULL;

  /***************** Resource event  ****************/
  event void SubRadioResource.granted() {
    uint8_t rc;

    rc = call SubSend.send( pending_message, pending_length );
    if (rc != SUCCESS) {
      call SubRadioResource.release();
      signal MacAMSend.sendDone( pending_message, rc );
    }
  }


  command error_t Mgmt.start() {
    if (status == S_STARTED) {
      dbg("Radio", "Radio cc2420 already started\n");
      signal Mgmt.startDone(SUCCESS);
      return SUCCESS;
    }

    call ParametersCC2420.set_sink_addr(call csmacaMacParams.get_sink_addr());
    call ParametersCC2420.set_channel(call csmacaMacParams.get_channel());
    call ParametersCC2420.set_power(call csmacaMacParams.get_power());
    call ParametersCC2420.set_remote_wakeup(call csmacaMacParams.get_remote_wakeup());
    call ParametersCC2420.set_delay_after_receive(call csmacaMacParams.get_delay_after_receive());
    call ParametersCC2420.set_backoff(call csmacaMacParams.get_backoff());
    call ParametersCC2420.set_min_backoff(call csmacaMacParams.get_min_backoff());
    call ParametersCC2420.set_ack(call csmacaMacParams.get_ack());
    call ParametersCC2420.set_cca(call csmacaMacParams.get_cca());
    call ParametersCC2420.set_crc(call csmacaMacParams.get_crc());

    dbg("Radio", "Radio cc2420 starts\n");

    if (call RadioControl.start() != SUCCESS) {
      signal Mgmt.startDone(FAIL);
    }
    status = S_STARTING;
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    if (status == S_STOPPED) {
      dbg("Radio", "Radio cc2420 already stopped\n");
      signal Mgmt.stopDone(SUCCESS);
      return SUCCESS;
    }

    dbg("Radio", "Radio cc2420 stops\n");

    if (call RadioControl.stop() != SUCCESS) {
      signal Mgmt.stopDone(FAIL);
    }
    status = S_STOPPING;
    return SUCCESS;
  }


  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    } else {
      if (status == S_STARTING) {
        dbg("Radio", "Radio cc2420 got RadioControl startDone\n");
        status = S_STARTED;
        signal MacStatus.status(F_RADIO, ON);
        signal Mgmt.startDone(SUCCESS);
      }
    }
  }


  event void RadioControl.stopDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.stop();
    } else {
      if (status == S_STOPPING) {
        dbg("Radio", "Radio cc2420 got RadioControl stopDone\n");
        status = S_STOPPED;
        signal MacStatus.status(F_RADIO, OFF);
        signal Mgmt.stopDone(SUCCESS);
      }
    }
  }

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );

    call MacAMPacket.setGroup(msg, msg->conf);
    dbg("Mac", "Mac sends msg on state %d\n", msg->conf);

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

    if (call SubRadioResource.immediateRequest() == SUCCESS) {
      error_t rc;

      rc = call SubSend.send( msg, len );
      if (rc != SUCCESS) {
        call SubRadioResource.release();
      }

      return rc;
    } else {
      pending_length  = len;
      pending_message = msg;
      return call SubRadioResource.request();
    }






  }

  command error_t MacAMSend.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    return call MacPacket.maxPayloadLength();
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    return call MacPacket.getPayload(msg, len);
  }

  event void csmacaMacParams.receive_status(uint16_t status_flag) {
  }


  event void RadioAMSend.sendDone(message_t *msg, uint8_t len) {
    dbg("Mac", "Mac: CSMA/CA sendDone\n");
    signal MacAMSend.sendDone(msg, len);
  }

  event message_t* RadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    dbg("Mac", "Mac: CSMA/CA receive\n");
    return signal MacReceive.receive(msg, payload, len);
  }

  event message_t* RadioSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    //dbg("Mac", "Mac: CSMA/CA snoop\n");
    return signal MacSnoop.receive(msg, payload, len);
  }


  event void RadioStatus.status(uint8_t layer, uint8_t status_flag) {
    return signal MacStatus.status(layer, status_flag);
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















  /***************** AMPacket Commands ****************/
  command am_addr_t MacAMPacket.address() {
    return TOS_NODE_ID;
  }

  command am_addr_t MacAMPacket.destination(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->dest;
  }

  command am_addr_t MacAMPacket.source(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->src;
  }

  command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->dest = addr;
  }

  command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->src = addr;
  }



  command bool MacAMPacket.isForMe(message_t* amsg) {
    return (call MacAMPacket.destination(amsg) == call MacAMPacket.address() ||
            call MacAMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t MacAMPacket.type(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->type;
  }

  command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->type = type;
  }

  command am_group_t MacAMPacket.group(message_t* amsg) {
    return (call CC2420PacketBody.getHeader(amsg))->destpan;
  }

  command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(amsg))->destpan = grp;
  }

  command am_group_t MacAMPacket.localGroup() {
    return 0;
//    return call CC2420Config.getPanAddr();
  }




  /***************** Packet Commands ****************/
  command void MacPacket.clear(message_t* msg) {
    memset(call CC2420PacketBody.getHeader(msg), 0x0, sizeof(cc2420_header_t));
    memset(call CC2420PacketBody.getMetadata(msg), 0x0, sizeof(cc2420_metadata_t));
  }

  command uint8_t MacPacket.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE;
  }

  command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE;
  }

  command uint8_t MacPacket.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }



  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    call SubRadioResource.release();
    signal MacAMSend.sendDone(msg, result);
  }



  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    cc2420_metadata_t *meta = call CC2420PacketBody.getMetadata(msg);

    msg->conf = call MacAMPacket.group(msg);

    msg->conf = call MacAMPacket.group(msg);
    msg->rssi = meta->rssi;
    msg->lqi = meta->lqi;
    msg->crc = meta->crc;

    if (call MacAMPacket.isForMe(msg)) {
      dbg("Radio", "Radio receives msg on state %d\n", msg->conf);
      return signal MacReceive.receive(msg, payload, len);
    }
    else {
      return signal MacSnoop.receive(msg, payload, len);
    }
  }


}

