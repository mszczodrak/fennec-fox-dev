/*
 *  gtdma mac module for Fennec Fox platform.
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
 * Module: gtdma Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "gtdmaMac.h"

module gtdmaMacP {

  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface gtdmaMacParams;

  uses interface Receive as RadioReceive;
  uses interface ModuleStatus as RadioStatus;
  uses interface RadioConfig;
  uses interface RadioPower;
  uses interface Read<uint16_t> as ReadRssi;
  uses interface Resource as RadioResource;
  uses interface RadioTransmit;
  uses interface StdControl as RadioControl;

  uses interface ReceiveIndicator as PacketIndicator;
  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface ReceiveIndicator as ByteIndicator;

}

implementation {

  command error_t Mgmt.start() {
    dbg("Mac", "Mac gtdma starts\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbg("Mac", "Mac gtdma stops\n");
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    dbg("Mac", "Mac: Null send\n");
    //return call RadioTransmit.send(addr, msg, len);
    return call RadioTransmit.load(msg);
  }

  command error_t MacAMSend.cancel(message_t* msg) {
    call RadioTransmit.cancel();
    return SUCCESS;
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    return 0;
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    return msg;
  }

  event message_t* RadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    dbg("Mac", "Mac: Null receive\n");
    return signal MacReceive.receive(msg, payload, len);
  }

  command am_addr_t MacAMPacket.address() {
    return TOS_NODE_ID;
  }

  command am_addr_t MacAMPacket.destination(message_t* amsg) {
    return 0;
  }

  command am_addr_t MacAMPacket.source(message_t* amsg) {
    return 0;
  }

  command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
  }

  command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
  }

  command bool MacAMPacket.isForMe(message_t* amsg) {
  }

  command am_id_t MacAMPacket.type(message_t* amsg) {
  }

  command void MacAMPacket.setType(message_t* amsg, am_id_t t) {
  }

  command am_group_t MacAMPacket.group(message_t* amsg) {
  }

  command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
  }

  command am_group_t MacAMPacket.localGroup() {
  }

  command void MacPacket.clear(message_t* msg) {
  }

  command uint8_t MacPacket.payloadLength(message_t* msg) {
    return 0;
  }

  command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
  }

  command uint8_t MacPacket.maxPayloadLength() {
    return 128;
  }

  command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
    return (void*) getHeader(msg);
  }

  async command error_t MacPacketAcknowledgements.requestAck( message_t* msg ) {
    return SUCCESS;
  }

  async command error_t MacPacketAcknowledgements.noAck( message_t* msg ) {
    return SUCCESS;
  }

  async command bool MacPacketAcknowledgements.wasAcked(message_t* msg) {
    return FALSE;
  }

  event void RadioStatus.status(uint8_t layer, uint8_t status_flag) {
    return signal MacStatus.status(layer, status_flag);
  }

  event void gtdmaMacParams.receive_status(uint16_t status_flag) {
  }


  async event void RadioPower.startVRegDone() {
  }

  async event void RadioPower.startOscillatorDone() {
  }

  event void RadioResource.granted() {
  }

  event void RadioConfig.syncDone(error_t error) {
  }

  event void ReadRssi.readDone(error_t error, uint16_t rssi) {
  }

  async event void RadioTransmit.loadDone(message_t* msg, error_t error) {
    call RadioTransmit.send(msg, 0);
  }

  async event void RadioTransmit.sendDone(error_t error) {
    signal MacAMSend.sendDone(NULL, error);
  }

}

