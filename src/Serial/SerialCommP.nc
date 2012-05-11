#include <Fennec.h>
#include "SerialComm.h"

module SerialCommP
{
  provides interface Serial;
  provides interface StdControl;
  
  uses interface SplitControl as SerialControl;
  uses interface Packet;
  uses interface AMSend as FrameSend;
  uses interface Receive;
  
}

implementation
{
  uint8_t *buffer;
  bigmsg_frame_request_t req;
  uint32_t total_size;

  message_t tx_msg;

  command error_t StdControl.start() {
    buffer = 0;
    return call SerialControl.start();
  }

  command error_t StdControl.stop() {
    return call SerialControl.stop();
  }

  task void processFrame()
  {
    bigmsg_frame_part_t *msgData =
      (bigmsg_frame_part_t *)call Packet.getPayload(&tx_msg, sizeof(bigmsg_frame_part_t));
    uint32_t buf_offset;
    uint8_t len;

    buf_offset = req.part_id<<BIGMSG_DATA_SHIFT;

    if (buf_offset >= total_size)
    {
      buffer = 0;
      signal Serial.sendDone(FAIL);
      return;
    }

    len = (total_size - buf_offset < BIGMSG_DATA_LENGTH) ? total_size - buf_offset : BIGMSG_DATA_LENGTH;

    msgData->part_id = req.part_id;
    memcpy(msgData->buf,&(buffer[buf_offset]),len);

    if (call FrameSend.send(AM_BROADCAST_ADDR, &tx_msg, len+BIGMSG_HEADER_LENGTH) == FAIL)
      post processFrame();
  }


  command error_t Serial.send(uint8_t *start_buf, uint32_t size) {
    if (size==0 )//|| busy==1)
    {
      signal Serial.sendDone(SUCCESS);
      return FAIL;
    }

    buffer = start_buf;
    req.part_id = 0;
    req.send_next_n_parts = size>>BIGMSG_DATA_SHIFT;
    total_size = size;
    post processFrame();
    return SUCCESS;
  }

  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {

    return msg;
  }

  event void FrameSend.sendDone(message_t* bufPtr, error_t error) {
    if (error==FAIL)
    {
      post processFrame();
      return;
    }
    if (req.send_next_n_parts)
    {
      req.part_id++;
      req.send_next_n_parts--;
      post processFrame();
    }
    else
      signal Serial.sendDone(SUCCESS);
  }

  event void SerialControl.startDone(error_t result){}
  event void SerialControl.stopDone(error_t result){}

}

