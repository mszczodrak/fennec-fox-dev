/*
 * Application: 
 * Author: 
 * Date: 
 */

#include <Fennec.h>
#include "SendPictureApp.h"

//#define FRAME_DELAY 10
#define FRAME_DELAY 4

generic module SendPictureAppP(uint16_t src, uint16_t dest, uint16_t pic_delay) {
  provides interface Mgmt;
  provides interface Module;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;

  uses interface Camera;

  uses interface Serial;
}

implementation {

  uint32_t data_size;
  uint32_t data_offset;
  uint8_t *data_buffer;
  uint8_t max_pic_size;

  command error_t Mgmt.start() {
    if (TOS_NODE_ID == src) {
      max_pic_size = call NetworkAMSend.maxPayloadLength() - sizeof(pic_header_t);
      max_pic_size = 90;
      call Timer0.startOneShot(1024);
    }

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Timer1.stop();
    call Leds.set(0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    //call Timer0.startOneShot(1024*pic_delay);  /* sends every PICTURE_DELAY seconds */
    call Camera.capture((uint8_t*)pic_frame, 0, 0);
    call Leds.led2On();
  }

  event void Timer1.fired() {
    pic_header_t* payload;
    message_t* message;

    payload = (pic_header_t*) call NetworkAMSend.getPayload(message, 0);
    payload->offset = data_offset;

    if (data_size > max_pic_size ) {
      memcpy(payload->frame, data_buffer+data_offset, max_pic_size);
    } else {
      memcpy(payload->frame, data_buffer+data_offset, data_size);
    }

    message->next_hop = dest;

    if ((call NetworkAMSend.send(dest, message, 0)) != SUCCESS) {
      dbg("Application", "simSendPicture failed to send frame\n");
    } else {
      if (data_size > max_pic_size) {
        data_offset += max_pic_size;
        data_size -= max_pic_size;
      } else {
        data_buffer = NULL;
        data_offset = 0;
        data_size = 0;
        /* start capturing picture right away, well 2 secd delay */
        //call Timer0.startOneShot(1024*pic_delay);
      }
    }
  }

  event void Camera.captureDone(uint8_t *buf, uint32_t size) {

    data_buffer = buf;
    data_size = size;
    data_offset = 0;
    call Leds.led1On();

    call Timer1.startOneShot(1);
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
    if (data_size == 0) {
      call Leds.set(0);
    } else {
      call Timer1.startOneShot(FRAME_DELAY);
    }
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    pic_header_t *pic = (pic_header_t*) payload;
    call Leds.led1Toggle();
    call Serial.send((void*)pic->frame, size-sizeof(pic_header_t));
    signal Module.drop_message(msg);
  }

  event void Serial.receive(void *buf, uint16_t len) {

  }

}
