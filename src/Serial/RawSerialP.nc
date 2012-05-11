#include <Fennec.h>
#include "RawSerial.h"

module RawSerialP
{
  provides interface Serial;
//  provides interface StdControl;
  
  uses interface UartByte;
  uses interface StdControl as UartControl;
}

implementation {

//  command error_t StdControl.start() {
//    call UartControl.start();
//    return SUCCESS;
//  }

//  command error_t StdControl.stop() {
//    call UartControl.stop();
//    return SUCCESS;
//  }

  command void Serial.send(void *buf, uint16_t size) {
    uint8_t *start_buf = (uint8_t*) buf;
    for(;size > 0; size--) {
      call UartByte.send((uint8_t)*start_buf);
      start_buf++;
    }

//    signal Serial.sendDone(SUCCESS);
    //return SUCCESS;
  }
}

