/*
 * Application: 
 * Author: 
 * Date: 
 */

#include <Fennec.h>
#include "BridgeApp.h"

generic module BridgeAppP() {

  provides interface Mgmt;
  uses interface Leds;
  uses interface NetworkCall;
  uses interface NetworkSignal;

  uses interface Serial;
  uses interface StdControl as SerialControl;
}

implementation {

  command error_t Mgmt.start() {
    setFennecStatus( F_BRIDGING, ON );
    call SerialControl.start();
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    setFennecStatus( F_BRIDGING, OFF );
    call SerialControl.stop();
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Serial.sendDone(error_t success){}

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {}

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    call Serial.send(payload, size);
    drop_message(msg);
  }

}
