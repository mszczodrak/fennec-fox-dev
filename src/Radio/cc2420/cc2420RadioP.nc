/*
 *  Dummy radio module for Fennec Fox platform.
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
 * Network: Dummy Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "cc2420Radio.h"

module cc2420RadioP @safe() {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;
  provides interface AMPacket as RadioAMPacket;
  provides interface Packet as RadioPacket;
  provides interface PacketAcknowledgements as RadioPacketAcknowledgements;
  provides interface ModuleStatus as RadioStatus;

  uses interface cc2420RadioParams;
  uses interface RadioConfig;

  uses interface StdControl as ReceiveControl;
  uses interface StdControl as TransmitControl;

  provides interface StdControl;
}

implementation {

  command error_t Mgmt.start() {
    call StdControl.start();
    dbg("Radio", "Radio cc2420 starts\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call StdControl.stop();
    dbg("Radio", "Radio cc2420 stops\n");
    signal Mgmt.stopDone( SUCCESS );
    return SUCCESS;
  }

  command error_t StdControl.start() {
    call ReceiveControl.start();
    call TransmitControl.start();
  }

  command error_t StdControl.stop() {
    call ReceiveControl.stop();
    call TransmitControl.stop();
  }

  command error_t RadioAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return SUCCESS;
  }

  command error_t RadioAMSend.cancel(message_t* msg) {
    return SUCCESS;
  }

  command uint8_t RadioAMSend.maxPayloadLength() {
    return 0;
  }

  command void* RadioAMSend.getPayload(message_t* msg, uint8_t len) {
    return NULL;
  }

  command am_addr_t RadioAMPacket.address() {
    return TOS_NODE_ID;
  }

  command am_addr_t RadioAMPacket.destination(message_t* amsg) {
    return TOS_NODE_ID;
  }

  command am_addr_t RadioAMPacket.source(message_t* amsg) {
    return TOS_NODE_ID;
  }

  command void RadioAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
  }

  command void RadioAMPacket.setSource(message_t* amsg, am_addr_t addr) {
  }

  command bool RadioAMPacket.isForMe(message_t* amsg) {
    return FALSE;
  }

  command am_id_t RadioAMPacket.type(message_t* amsg) {
    return 0;
  }

  command void RadioAMPacket.setType(message_t* amsg, am_id_t t) {
  }

  command am_group_t RadioAMPacket.group(message_t* amsg) {
    return 0;
  }

  command void RadioAMPacket.setGroup(message_t* amsg, am_group_t grp) {
  }

  command am_group_t RadioAMPacket.localGroup() {
    return 0;
  }

  command void RadioPacket.clear(message_t* msg) {
  }

  command uint8_t RadioPacket.payloadLength(message_t* msg) {
    return 0;
  }

  command void RadioPacket.setPayloadLength(message_t* msg, uint8_t len) {
  }

  command uint8_t RadioPacket.maxPayloadLength() {
    return 128;
  }

  command void* RadioPacket.getPayload(message_t* msg, uint8_t len) {
    return (void*)msg;
  }

  async command error_t RadioPacketAcknowledgements.requestAck( message_t* msg ) {
    return SUCCESS;
  }

  async command error_t RadioPacketAcknowledgements.noAck( message_t* msg ) {
    return SUCCESS;
  }

  async command bool RadioPacketAcknowledgements.wasAcked(message_t* msg) {
    return 1;
  }

  event void cc2420RadioParams.receive_status(uint16_t status_flag) {
  }


  /****************** RadioConfig Events ****************/
  event void RadioConfig.syncDone( error_t error ) {
  }

}

