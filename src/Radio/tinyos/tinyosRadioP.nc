#include <Fennec.h>
#include "tinyosRadio.h"

generic module tinyosRadioP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Receive as ReceiveReceive;
  uses interface PacketAcknowledgements;

  uses interface Timer<TMilli> as Timer0;
}

implementation {

  message_t out_tos;
  uint16_t next_hop;
  msg_t *out_msg;
  uint8_t tr_state = S_STOPPED;

  command error_t Mgmt.start() {
    if (tr_state == S_STARTED) {
      signal Mgmt.startDone(SUCCESS);
    } else {
      tr_state = S_STARTING;
      call AMControl.start();
    }
    return SUCCESS;
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (tr_state == S_STARTING) {
        tr_state = S_STARTED;
        signal Mgmt.startDone(SUCCESS);
      }
    } else {
      if (tr_state == S_STARTING) {
        call AMControl.start();
      }
    }
  }

  command error_t Mgmt.stop() {
    if (tr_state == S_STOPPED) {
      signal Mgmt.stopDone(SUCCESS);
    } else {
      call Timer0.stop();
      tr_state = S_STOPPING;
      call AMControl.stop();
    }
    return SUCCESS;
  }

  event void AMControl.stopDone(error_t err) {
    if (err == SUCCESS) {
      if (tr_state == S_STOPPING) {
        tr_state = S_STOPPED;
        signal Mgmt.stopDone(err);
      }
    } else {
      if (tr_state == S_STOPPING) {
        call AMControl.stop();
      }
    }
  }

  event void Timer0.fired() {
    tr_state = S_STARTED;
    dbg("Radio", "Radio AM timer fired\n");
    signal RadioSignal.sendDone(out_msg, FAIL);
  }

  task void load_done_task()
  {
    signal RadioSignal.loadDone(out_msg, SUCCESS);
  }


  command error_t RadioCall.load(msg_t *msg) {
    uint8_t *payload;

    dbg("Radio", "Radio got message to load\n");

    if (tr_state != S_STARTED) {
      signal RadioSignal.loadDone(msg, FAIL);
      return FAIL;
    }

    out_msg = msg;

    payload = call AMSend.getPayload(&out_tos, msg->len);

    if (payload == NULL) {
      signal RadioSignal.loadDone(msg, FAIL);
      return FAIL;
    }

    memcpy(payload, msg->data, msg->len);
    {
      //uint8_t *d = payload;
      //dbg("Radio", "Ready to send\n");
      //dbg("Radio", "%d %d %d %d %d %d %d %d %d\n", d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]);
    }

    if (msg->next_hop == BROADCAST) {
      next_hop = AM_BROADCAST_ADDR;
    } else {
      next_hop = msg->next_hop;
      call PacketAcknowledgements.requestAck(&out_tos);
    }

    post load_done_task();

    return SUCCESS;
  }

  command error_t RadioCall.send(msg_t *msg) {

    if((call AMSend.send(next_hop, &out_tos, out_msg->len)) != SUCCESS) {
      dbg("Radio", "Radio failed to send\n");
      tr_state = S_STARTED;
      signal RadioSignal.sendDone(out_msg,FAIL);
      return FAIL;
    }

    call Timer0.startOneShot(TINYOS_RADIO_MAX_BUSY_LENGTH);

    dbg("Radio", "Radio Transmitting\n");
    tr_state = S_TRANSMITTING;
    return SUCCESS;
  }

  command uint8_t RadioCall.getMaxSize(msg_t *msg) {
    return TINYOS_MAX_MESSAGE_SIZE;
  }

  command uint8_t* RadioCall.getPayload(msg_t *msg) {
    return (uint8_t*)&msg->data;
  }

  command error_t RadioCall.resend(msg_t *msg) {
    return SUCCESS;
  }

  command error_t RadioCall.cancel(msg_t *msg) {
    return SUCCESS;
  }

  command uint8_t RadioCall.sampleCCA(msg_t *msg) {
    /* one means CCA is clean so can send */
    return 1;
  }

  event message_t* ReceiveReceive.receive(message_t* in_msg, void* payload, uint8_t len) {
    msg_t *new_msg;
    nx_struct fennec_header *fh;

#ifndef TOSSIM
    cc2420_metadata_t *meta;
#else
    tossim_metadata_t* meta;
#endif

    dbg("Radio", "Radio Receive message\n");

    if (tr_state == S_STOPPED) {
      return in_msg;
    }

    if ((new_msg = signal Module.next_message()) == NULL) {
      return in_msg;
    }

#ifndef TOSSIM
    meta = (cc2420_metadata_t*) in_msg->metadata;
#else
    meta = (tossim_metadata_t*) in_msg->metadata;
#endif

    {
      //uint8_t *d = payload;
      //dbg("Radio", "Ready to copy\n");
      //dbg("Radio", "%d %d %d %d %d %d %d %d %d\n", d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]);


    }

    new_msg->len = len;
    memcpy(new_msg, payload, len);
    fh = (nx_struct fennec_header*)payload;
    new_msg->fennec.len = fh->len;
    new_msg->fennec.conf = fh->conf;

#ifndef TOSSIM
    new_msg->rssi = meta->rssi;
    new_msg->lqi = meta->lqi;
#else
    new_msg->rssi = meta->strength;
    new_msg->lqi = meta->strength;
#endif

    //dbg("Radio", "Ready copy done\n");

    if (signal RadioSignal.check_destination(new_msg, payload) == TRUE) {
      //dbg("Radio", "Radio signal receive\n");
      signal RadioSignal.receive(new_msg, (uint8_t*)&new_msg->data, new_msg->len);
    } else {
      //dbg("Radio", "Radio - it's not for me\n");
      signal Module.drop_message(new_msg);
    }
    return in_msg;
  }

  event void AMSend.sendDone(message_t* out, error_t error){
    tr_state = S_STARTED;
    call Timer0.stop();
    //dbg("Radio", "Radio got AMSend done\n");
    {
      //uint8_t *d = (uint8_t*)&out_msg->data;
      //dbg("Radio", "%d %d %d %d %d %d %d %d %d\n", d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]);
      //dbg("Radio", "C %d L %d %d\n", out_msg->fennec.conf, out_msg->fennec.len, out_msg->len);
    }

    if (next_hop != AM_BROADCAST_ADDR && !call PacketAcknowledgements.wasAcked(out)) {
      dbg("Radio", "Radio did not get ACK\n");
      error = FAIL;
    }

    signal RadioSignal.sendDone(out_msg, error);
    //dbg("Radio", "Radio send done signaled\n");
  }

}

