/*
 *  TDMA MAC module for Fennec Fox platform.
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
 * Module: TDMA MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "tdmaMac.h"

#include <Ieee154.h> 
#include "CC2420.h"
#include "tdmaMac.h"
#include "TimeSyncMessage.h"

module tdmaMacP @safe() {
  provides interface Mgmt;
  provides interface ModuleStatus as MacStatus;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;

  provides interface Packet as MacPacket;
  provides interface AMPacket as MacAMPacket;

  provides interface PacketAcknowledgements as MacPacketAcknowledgements;

  provides interface AMSend as FtspMacAMSend;
  provides interface Receive as FtspMacReceive;

  uses interface tdmaMacParams;

  uses interface SplitControl as RadioControl;

  uses interface ModuleStatus as RadioStatus;

  uses interface RadioConfig;
  uses interface RadioPower;
  uses interface Read<uint16_t> as ReadRssi;
  uses interface Resource as RadioResource;

  uses interface Send as SubSend;
  uses interface Receive as SubReceive;

  uses interface Random;
  uses interface Leds;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface ReceiveIndicator as ByteIndicator;
  uses interface ReceiveIndicator as PacketIndicator;

  uses interface Queue<message_t*> as SendQueue;

  uses interface PacketTimeStamp<TMilli,uint32_t>;
  uses interface GlobalTime<TMilli>;
  uses interface TimeSyncInfo;
  uses interface TimeSyncMode;
  uses interface TimeSyncNotify;

  uses interface Timer<TMilli> as PeriodTimer;
  uses interface Timer<TMilli> as FrameTimer;

  uses interface StdControl as TimerControl;

}

implementation {

  uint8_t status = S_STOPPED;
  uint32_t tdma_time;
  uint32_t active_time;
  uint32_t sleep_time;
  bool radio_status = OFF;
  error_t err;
  bool received_beacon = TRUE;

  message_t * ftsp_sync_message = NULL;

  uint8_t localSendId;

  /**
   * Radio Power, Check State, and Duty Cycling State
   */
  enum {
    S_OFF, // off by default
    S_TURNING_ON,
    S_ON,
    S_TURNING_OFF,
  };

  norace uint32_t local, global;
  norace error_t sync = FAIL;
  norace bool busy_sending = FALSE;

  /* Functions */

  void correct_period_time() {
    atomic {
      /* get global time */
      sync = call GlobalTime.getGlobalTime(&global);

      if (sync != SUCCESS) {
        /* if the clock is not synced, continue without adjusting the period */
        call PeriodTimer.startOneShot(tdma_time);
        return;
      }

      local = global;
      /* compute the next global period */
      local = global + (tdma_time - (global % tdma_time));

      call GlobalTime.global2Local(&local);
      local = local - call GlobalTime.getLocalTime();

      call PeriodTimer.startOneShot(local);

      //printf("%lu:  firing in %lu\n", global, local);
      //printfflush();
    }
  }

  void start_synchronization() {
    if ( (call tdmaMacParams.get_root_addr() == TOS_NODE_ID) || 
         (sync == SUCCESS) ){
      call TimeSyncMode.send();
    }
  }

  task void start_done() {
    signal Mgmt.startDone(err);
  }

  task void stop_done() {
    signal Mgmt.stopDone(err);
  }

  task void try_send_network_message() {
    tdma_header_t* header;
    message_t *next_msg;

    if ((radio_status == OFF) || ((call SendQueue.empty()) && (ftsp_sync_message == NULL)) || (busy_sending == TRUE)) {
      /* if we can't route packages OR there are no messages to send
       * OR we're busy with sending other messages, then skip transmission
       */
      return;
    }

    if ((ftsp_sync_message != NULL)) {
      next_msg = ftsp_sync_message;
      ftsp_sync_message = NULL;
    } else {
      next_msg = call SendQueue.head();
    }

    header = (tdma_header_t*)getHeader( next_msg );

    if (call SubSend.send(next_msg, header->length) == SUCCESS) {
      busy_sending = TRUE;
    }
  }

  command error_t Mgmt.start() {
    busy_sending = FALSE;
    local = global = 0;
    radio_status = OFF;
    received_beacon = TRUE;

    active_time = call tdmaMacParams.get_active_time();
    sleep_time = call tdmaMacParams.get_sleep_time();
    tdma_time = active_time + sleep_time;

    if (status == S_STARTED) {
      err = SUCCESS;
      post start_done();
      return SUCCESS;
    }

    localSendId = call Random.rand16();

    err = call RadioControl.start();

    if (err == FAIL) {
      post start_done();
      return FAIL;
    }

    call TimerControl.start();

//    if (call GlobalTime.getGlobalTime(&global) == SUCCESS) {
      //call PeriodTimer.startOneShot(tdma_time / 2);
      call PeriodTimer.startOneShot(tdma_time);
//    } else {
//      call PeriodTimer.startOneShot(tdma_time * 2);
//      //call PeriodTimer.startOneShot(tdma_time);
//    }

    status = S_STARTING;
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call PeriodTimer.stop();
    call FrameTimer.stop();
    call TimerControl.stop();

    if (status == S_STOPPED) {
      err = SUCCESS;
      post stop_done();
      return SUCCESS;
    }

    err = call RadioControl.stop();

    if (err == FAIL) {
      err = FAIL;
      post stop_done();
    }

    status = S_STOPPING;
    return SUCCESS;
  }

  event void RadioControl.startDone(error_t error) {
    //printf("radio start done\n");
    //printfflush();
    switch(error){
    case EALREADY:
      radio_status = ON;
      if (status == S_STARTING) {
        status = S_STARTED;
        signal MacStatus.status(F_RADIO, ON);
        err = SUCCESS;
        post start_done();
      }
      start_synchronization();
      break;

    case SUCCESS:
      radio_status = ON;
      if (status == S_STARTING) {
        status = S_STARTED;
        signal MacStatus.status(F_RADIO, ON);
        err = SUCCESS;
        post start_done();
      }
      start_synchronization();
      break;

    default:
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t error) {
    //printf("radio stop done\n");
    //printfflush();
    switch(error){
    case EALREADY:
      radio_status = OFF;
      if (status == S_STOPPING) {
        status = S_STOPPED;
        signal MacStatus.status(F_RADIO, OFF);
        err = SUCCESS;
        post stop_done();
      }
      break;

    case SUCCESS:
      radio_status = OFF;
      if (status == S_STOPPING) {
        status = S_STOPPED;
        signal MacStatus.status(F_RADIO, OFF);  
        err = SUCCESS;
        post stop_done();
      }
      break;

    default:
      call RadioControl.stop();
    }
  }

  command error_t FtspMacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    ftsp_sync_message = msg;
    return call MacAMSend.send(addr, msg, len);
  }

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    tdma_header_t* header = (tdma_header_t*)getHeader( msg );

    if (call SendQueue.full()) {
      /* we have no space to store another message */
      return EBUSY;
    }

    call MacAMPacket.setGroup(msg, msg->conf);

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

    if ((ftsp_sync_message != NULL) && (ftsp_sync_message != msg)) {
      if (call SendQueue.enqueue(msg) == SUCCESS) {
        post try_send_network_message();
        return SUCCESS;
      } 
      return FAIL;
    }
    post try_send_network_message();
    return SUCCESS;
  }

  command error_t FtspMacAMSend.cancel(message_t* msg) {
    return call MacAMSend.cancel(msg);
  }

  command error_t MacAMSend.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t FtspMacAMSend.maxPayloadLength() {
    return call MacAMSend.maxPayloadLength();
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    return call MacPacket.maxPayloadLength();
  }

  command void* FtspMacAMSend.getPayload(message_t* msg, uint8_t len) {
    return call MacAMSend.getPayload(msg, len);
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    return call MacPacket.getPayload(msg, len);
  }

  /***************** PacketAcknowledgement Commands ****************/
  async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
    tdma_header_t* header = (tdma_header_t*)getHeader(p_msg);
    header->fcf |= 1 << IEEE154_FCF_ACK_REQ;
    return SUCCESS;
  }

  async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
    tdma_header_t* header = (tdma_header_t*)getHeader(p_msg);
    header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
    return SUCCESS;
  }

  async command bool MacPacketAcknowledgements.wasAcked( message_t* p_msg ) {
    metadata_t* metadata = (metadata_t*) p_msg->metadata;
    return metadata->ack;
  }

  event void tdmaMacParams.receive_status(uint16_t status_flag) {
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
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    return header->dest;
  }

  command am_addr_t MacAMPacket.source(message_t* amsg) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    return header->src;
  }

  command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    header->dest = addr;
  }

  command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    header->src = addr;
  }



  command bool MacAMPacket.isForMe(message_t* amsg) {
    return (call MacAMPacket.destination(amsg) == call MacAMPacket.address() ||
            call MacAMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t MacAMPacket.type(message_t* amsg) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    return header->type;
  }

  command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    header->type = type;
  }

  command am_group_t MacAMPacket.group(message_t* amsg) {
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    return header->destpan;
  }

  command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
    // Overridden intentionally when we send()
    tdma_header_t* header = (tdma_header_t*)getHeader(amsg);
    header->destpan = grp;
  }

  command am_group_t MacAMPacket.localGroup() {
    return 0;
//    return call CC2420Config.getPanAddr();
  }




  /***************** Packet Commands ****************/
  command void MacPacket.clear(message_t* msg) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    tdma_header_t* header = (tdma_header_t*)getHeader(msg);
    memset(header, 0x0, sizeof(tdma_header_t));
    memset(metadata, 0x0, sizeof(metadata_t));
  }

  command uint8_t MacPacket.payloadLength(message_t* msg) {
    tdma_header_t* header = (tdma_header_t*)getHeader(msg);
    return header->length - CC2420_SIZE;
  }

  command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
    tdma_header_t* header = (tdma_header_t*)getHeader(msg);
    header->length  = len + CC2420_SIZE;
  }

  command uint8_t MacPacket.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
    if (len <= call SubSend.maxPayloadLength()) {
      return msg->data;
    } else {
      return NULL;
    }

    //return call SubSend.getPayload(msg, len);
  }

  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    tdma_header_t* header = (tdma_header_t*)getHeader(msg);
    busy_sending = FALSE;
    if (header->type == AM_TIMESYNCMSG) {
      signal FtspMacAMSend.sendDone(msg, result);
      if ( radio_status == ON ) {
        /* continue synchronization */
        start_synchronization();
        return;
      }
    } else {
      if (msg == call SendQueue.head()) {
        call SendQueue.dequeue();
      }
      signal MacAMSend.sendDone(msg, result);
    }
    post try_send_network_message();
  }

  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    tdma_header_t* header = (tdma_header_t*)getHeader(msg);

    //printf("receive msg\n");

    if((call tdmaMacParams.get_crc()) && (!(metadata)->crc)) {
      //printf("failed crc\n");
      //printfflush();
      return msg;
    }

    msg->rssi = metadata->rssi;
    msg->lqi = metadata->lqi;
    msg->crc = metadata->crc;

    if (call MacAMPacket.isForMe(msg)) {
      if (header->type == AM_TIMESYNCMSG) {
        return signal FtspMacReceive.receive(msg, payload, len);
      } else {

	/* add info about new message */

        return signal MacReceive.receive(msg, payload, len);
      }
    }
    else {
      //printf("failed destination\n");
      //printfflush();
      return signal MacSnoop.receive(msg, payload, len);
    }
  }

  event void PeriodTimer.fired() {

    /* get global time */
    sync = call GlobalTime.getGlobalTime(&global);

    if (sync != SUCCESS) {
      /* if the clock is not synced, continue without adjusting the period */
      call FrameTimer.startOneShot(active_time);
    } else {
      local = global;

      /* compute the last global period */
      local = global - (global % tdma_time);
  
      /* get next start of the sleep time */
      local = local + active_time;

      if (local < global)
        local = local + tdma_time;

      call GlobalTime.global2Local(&local);
      local = local - call GlobalTime.getLocalTime();
      call FrameTimer.startOneShot(local);
    }

    /* turn on radio */
    call Leds.set(1);
    call RadioControl.start();
    call TimerControl.start();

//    if (call tdmaMacParams.get_root_addr() != TOS_NODE_ID) {
//TODO: can we do better than that?
//      received_beacon = FALSE;
//    }
  }

  event void FrameTimer.fired() {
    correct_period_time();
    /* turn off radio only when timer is synced */
    if ((sync == SUCCESS) && (received_beacon == TRUE)) {
      call Leds.set(4);
      call RadioControl.stop();
      busy_sending = FALSE;
      call TimerControl.stop();
      if (ftsp_sync_message != NULL) {
        signal FtspMacAMSend.sendDone(ftsp_sync_message, FAIL);
        ftsp_sync_message = NULL;
      }
    } else {
      call Leds.set(2);
    }
  }

  event void TimeSyncNotify.msg_received() {
    local = global = call GlobalTime.getLocalTime();
    sync = call GlobalTime.getGlobalTime(&global);
    received_beacon = TRUE;

    if (sync == SUCCESS) {
      //printf("synchronized\n");
      //printfflush();
      dbgs(F_MAC, S_STARTED, DBGS_SYNC, (uint16_t)(global>>16),(uint16_t)global);
      start_synchronization();
    } else {
      //printf("received\n");
      //printfflush();
      dbgs(F_MAC, S_STARTED, DBGS_RECEIVE_BEACON, (uint16_t)(global>>16),(uint16_t)global);
    }    
  }

  event void TimeSyncNotify.msg_sent() {
    local = global = call GlobalTime.getLocalTime();
    sync = call GlobalTime.getGlobalTime(&global);
    dbgs(F_MAC, S_STARTED, DBGS_SEND_BEACON, (uint16_t)(global>>16),(uint16_t)global);
  }

}
