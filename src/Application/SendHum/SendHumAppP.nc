#include <Fennec.h>

#include "SendHumApp.h"

#define ADDRESS 0

module SendHumAppP {

  provides interface SplitControl;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as Humidity;

  uses interface NetworkSend;
  uses interface NetworkReceive;
}

implementation {

  uint16_t counter;
  hum_msg_t message;

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
    if (call Humidity.read() != SUCCESS) {

    }
  }

  event void NetworkReceive.receive(void* msg, void *payload, uint8_t size) {
    hum_msg_t *hum = payload;
    call Leds.set(hum->counter);
    printf("Received counter %d and humidity %d\n", hum->counter, hum->value);
    printfflush();
    drop_message(msg);
  }

  event void NetworkSend.sendDone(error_t err) {

  }

  event void Humidity.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      message.counter = counter;
      message.value = val;
      call NetworkSend.send(ADDRESS, (void*) &message, sizeof(hum_msg_t));
    }
  }
}

