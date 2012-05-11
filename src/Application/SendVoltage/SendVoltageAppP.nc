#include <Fennec.h>
#include "SendVoltageApp.h"

#define ADDRESS 0

module SendVoltageAppP {

  provides interface SplitControl;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as Voltage;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter;

  command error_t SplitControl.start() {
    counter = 0;

    if (TOS_NODE_ID == 0) {
      setFennecStatus( F_BRIDGING, ON );
      setFennecStatus( F_PRINTING, ON );
    } else {
       call Timer0.startPeriodic(SEND_DELAY);
    }
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    call Timer0.stop();
    call Leds.set(0);
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    counter++;
    call Leds.set(counter);
    if (call Voltage.read() != SUCCESS) {

    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {

    drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    voltage_msg_t *voltage = (voltage_msg_t*)payload;
    call Leds.set(voltage->counter);
    printf("Received counter %d and battery %d\n", voltage->counter, voltage->value);
    printfflush();
    drop_message(msg);
  }

  event void Voltage.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      msg_t *msg = nextMessage();
      voltage_msg_t *voltage = (voltage_msg_t*) call NetworkCall.getPayload(msg);
      voltage->counter = counter;
      voltage->value = val;
      msg->len = sizeof(voltage_msg_t);
      msg->next_hop = ADDRESS;
      call NetworkCall.send(msg);
    }
  }
}
