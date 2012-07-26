/*
 *  LinkQuality mac module for Fennec Fox platform.
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
 * Network: LinkQuality Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "linkqualityMac.h"

module linkqualityMacP {

  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface linkqualityMacParams;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds;

  uses interface SplitControl as SerialCtrl;
  uses interface AMSend as SerialAMSend;
  uses interface Packet as SerialPacket;
}

implementation {

  message_t new_msg;

  command error_t Mgmt.start() {
    dbg("Mac", "Mac linkquality starts\n");
    if (TOS_NODE_ID == call linkqualityMacParams.get_src()) {
      call Timer.startPeriodic(call linkqualityMacParams.get_delay_ms());
    } else {
      call SerialCtrl.start();
    }
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbg("Mac", "Mac linkquality stops\n");
    call SerialCtrl.stop();
    call Timer.stop();
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer.fired() {
    nx_struct linkquality_mac_beacon *pkt = 
		(nx_struct linkquality_mac_beacon*) call 
		RadioPacket.getPayload(&new_msg, 
		sizeof(nx_struct linkquality_mac_beacon));
    pkt->src = TOS_NODE_ID;

    call Leds.led0Off();

    if (call RadioAMSend.send(AM_BROADCAST_ADDR, &new_msg, 
	sizeof(nx_struct linkquality_mac_beacon)) == SUCCESS) {
      call Leds.led1Toggle();
    } else {
      call Leds.led0Toggle();
    }
  }

  event void SerialCtrl.startDone(error_t status) {}
  event void SerialCtrl.stopDone(error_t status) {}
  event void SerialAMSend.sendDone(message_t *msg, uint8_t len) {}

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    dbg("Mac", "Mac: LinkQuality send\n");
    return call RadioAMSend.send(addr, msg, len);
  }

  command error_t MacAMSend.cancel(message_t* msg) {
    return call RadioAMSend.cancel(msg);
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    //dbg("Mac", "Mac: LinkQuality maxPayloadLength\n");
    return call RadioAMSend.maxPayloadLength();
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    //dbg("Mac", "Mac: LinkQuality getPayload\n");
    return call RadioAMSend.getPayload(msg, len);
  }

  event void RadioAMSend.sendDone(message_t *msg, uint8_t len) {
    dbg("Mac", "Mac: LinkQuality sendDone\n");
    signal MacAMSend.sendDone(msg, len);
  }

  event message_t* RadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    nx_struct linkquality_mac_beacon *in_msg;
    nx_struct linkquality_mac_serial *pkt;
    cc2420_metadata_t* m;


    in_msg = (nx_struct linkquality_mac_beacon*) payload;
    pkt = (nx_struct linkquality_mac_serial*) call
				SerialPacket.getPayload(&new_msg, 
				sizeof(nx_struct linkquality_mac_serial));

    m = (cc2420_metadata_t*) msg->metadata;
    dbg("Mac", "Mac: LinkQuality receive\n");
    pkt->from = in_msg->src;
    pkt->rssi = m->rssi;
    pkt->lqi = m->lqi;

    call Leds.led0Off();

    if (call SerialAMSend.send(AM_BROADCAST_ADDR, &new_msg, 
			sizeof(nx_struct linkquality_mac_serial)) == SUCCESS) {
      call Leds.led2Toggle();
    } else {
      call Leds.led0Toggle();
    }

    return signal MacReceive.receive(msg, payload, len);
  }

  event message_t* RadioSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    //dbg("Mac", "Mac: LinkQuality snoop\n");
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

  event void linkqualityMacParams.receive_status(uint16_t status_flag) {
  }


}

