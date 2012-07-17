/*
 *  Broadcast mac module for Fennec Fox platform.
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
 * Network: Broadcast Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "broadcastMac.h"

module broadcastMacP {

  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;

  uses interface Leds;
  uses interface Timer<TMilli> as Timer;

  uses interface broadcastMacParams;

  uses interface SplitControl as SerialCtrl;
  uses interface AMSend as SerialAMSend;
  uses interface Packet as SerialPacket;
}

implementation {

  message_t bcast;
  uint8_t n;
  uint8_t report;
  nx_uint16_t neighborhood[MAX_NEIGHBORHOOD_SIZE];
  void check_neighborhood(uint16_t addr);
  void clear_neighborhood();
  task void show_neighborhood();

  command error_t Mgmt.start() {
    call SerialCtrl.start();
    call Timer.startPeriodic(TX_PERIOD);
    clear_neighborhood();
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbg("Mac", "Mac broadcast stops\n");
    call Timer.stop();
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    dbg("Mac", "Mac: Broadcast send\n");
    return call RadioAMSend.send(addr, msg, len);
  }

  command error_t MacAMSend.cancel(message_t* msg) {
    return call RadioAMSend.cancel(msg);
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    //dbg("Mac", "Mac: Broadcast maxPayloadLength\n");
    return call RadioAMSend.maxPayloadLength();
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    //dbg("Mac", "Mac: Broadcast getPayload\n");
    return call RadioAMSend.getPayload(msg, len);
  }

  event void RadioAMSend.sendDone(message_t *msg, uint8_t len) {
    //printf("radio senddone\n");
    //printfflush();
    if (++report >= REPORT_PERIOD) {
      post show_neighborhood();
    }
//    signal MacAMSend.sendDone(msg, len);
  }

  event message_t* RadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    nx_struct broadcast_header *header = (nx_struct broadcast_header*) payload;
    call Leds.set(header->src);
    check_neighborhood(header->src);
    dbg("Mac", "Mac: Broadcast receive\n");
    return msg;
//    return signal MacReceive.receive(msg, payload, len);
  }

  event message_t* RadioSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return signal MacSnoop.receive(msg, payload, len);
  }

  command am_addr_t MacAMPacket.address() {
    return call RadioAMPacket.address();
  }

  command am_addr_t MacAMPacket.destination(message_t* amsg) {
    return call RadioAMPacket.destination(amsg);
  }

  command am_addr_t MacAMPacket.source(message_t* amsg) {
    return call RadioAMPacket.source(amsg);
  }

  command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    return call RadioAMPacket.setDestination(amsg, addr);
  }

  command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
    return call RadioAMPacket.setSource(amsg, addr);
  }

  command bool MacAMPacket.isForMe(message_t* amsg) {
    return call RadioAMPacket.isForMe(amsg);
  }

  command am_id_t MacAMPacket.type(message_t* amsg) {
    return call RadioAMPacket.type(amsg);
  }

  command void MacAMPacket.setType(message_t* amsg, am_id_t t) {
    return call RadioAMPacket.setType(amsg, t);
  }

  command am_group_t MacAMPacket.group(message_t* amsg) {
    return call RadioAMPacket.group(amsg);
  }

  command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
    return call RadioAMPacket.setGroup(amsg, grp);
  }

  command am_group_t MacAMPacket.localGroup() {
    return call RadioAMPacket.localGroup();
  }

  command void MacPacket.clear(message_t* msg) {
    return call RadioPacket.clear(msg);
  }

  command uint8_t MacPacket.payloadLength(message_t* msg) {
    return call RadioPacket.payloadLength(msg);
  }

  command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return call RadioPacket.setPayloadLength(msg, len);
  }

  command uint8_t MacPacket.maxPayloadLength() {
    return call RadioPacket.maxPayloadLength();
  }

  command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
    return call RadioPacket.getPayload(msg, len);
  }

  async command error_t MacPacketAcknowledgements.requestAck( message_t* msg ) {
    return call RadioPacketAcknowledgements.requestAck(msg);
  }

  async command error_t MacPacketAcknowledgements.noAck( message_t* msg ) {
    return call RadioPacketAcknowledgements.noAck(msg);
  }

  async command bool MacPacketAcknowledgements.wasAcked(message_t* msg) {
    return call RadioPacketAcknowledgements.wasAcked(msg);
  }

  event void RadioStatus.status(uint8_t layer, uint8_t status_flag) {
    return signal MacStatus.status(layer, status_flag);
  }

  event void SerialCtrl.startDone(error_t err) {}
  event void SerialCtrl.stopDone(error_t err) {}

  event void SerialAMSend.sendDone(message_t* bufPtr, error_t error) {
  }

  event void Timer.fired() {
    nx_struct broadcast_header *header = (nx_struct broadcast_header*)
	call RadioPacket.getPayload(&bcast, sizeof(nx_struct broadcast_header));
    header->src = TOS_NODE_ID;
    if ( call RadioAMSend.send(BROADCAST, &bcast, 
		sizeof(nx_struct broadcast_header)) != SUCCESS) {

    }
  }

  void check_neighborhood(uint16_t addr) {
    uint8_t i;
    for(i = 0; i < MAX_NEIGHBORHOOD_SIZE; i++) {
      if (neighborhood[i] == addr)
        return;
    }
    neighborhood[n] = addr;
    n = (n + 1) % MAX_NEIGHBORHOOD_SIZE; 
  }

  void clear_neighborhood() {
    for (n = 0; n < MAX_NEIGHBORHOOD_SIZE; n++) {
      neighborhood[n] = 0;
    }
    n = 0;
    report = 0;
  }

  task void show_neighborhood() {
    uint8_t *spkt = (uint8_t*) call SerialPacket.getPayload(&bcast, 
			sizeof(neighborhood) + 1);
    *spkt = n;
    spkt++;
    memcpy(spkt, neighborhood, MAX_NEIGHBORHOOD_SIZE);
    call SerialAMSend.send(AM_BROADCAST_ADDR, &bcast, 
			sizeof(neighborhood) + 1);
    clear_neighborhood();
  }

  event void broadcastMacParams.receive_status(uint16_t status_flag) {
  }

}


