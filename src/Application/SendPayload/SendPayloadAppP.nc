#include <Fennec.h>
#include "SendPayloadApp.h"

#define COUNTER_SOURCE 1
#define COUNTER_DESTINATION 2
#define PAYLOAD_DELAY (1024 * 60 * 5)
//#define SHORT_DELAY 10
#define SHORT_DELAY 50
#define TOTAL_PAYLOAD_SIZE 768
#define QUICK 1

generic module SendPayloadAppP() {
  provides interface Mgmt;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter;

  command error_t Mgmt.start() {
    counter = 0;
    switch(TOS_NODE_ID) {

      case COUNTER_DESTINATION:
        setFennecStatus( F_BRIDGING, ON );
        break;
   
      case COUNTER_SOURCE:
        if (QUICK) {
          call Timer0.startOneShot(SHORT_DELAY);
        } else {
          //call Timer0.startPeriodic(PAYLOAD_DELAY);
          call Timer0.startPeriodic(SHORT_DELAY);
        }
        break;
 
      default:
//        call Timer0.startPeriodic(PAYLOAD_DELAY);
        break;
    }

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Leds.set(0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  task void sendPayload() {
    msg_t* message = nextMessage();
    nx_struct payload_msg *c;

    if (counter > TOTAL_PAYLOAD_SIZE) {
      drop_message(message);
      call Timer0.stop();
      return;
    }

    if (message == NULL) {
      call Timer0.startOneShot(SHORT_DELAY);
    }
    c = (nx_struct payload_msg*) call NetworkCall.getPayload(message);

    c->counter = counter;
    call Leds.set(counter);

    message->len = sizeof(nx_struct payload_msg);
    message->next_hop = COUNTER_DESTINATION;

    dbg("Application", "Application: Sending counter %d with total size %d\n", c->counter, message->len);

    //serialSend(F_APPLICATION, 0, 0, 0, 1, counter);

    if (call NetworkCall.send(message) != SUCCESS) {
      drop_message(message);
      call Timer0.startOneShot(SHORT_DELAY);
      dbg("Application", "Application: Failed to send - short delay: %d\n", SHORT_DELAY);
    }
  }

  event void Timer0.fired() {
//    dbg("Application", "Application timer fired\n");
    //serialSend(F_APPLICATION, 0, 0, 0, 0, 0);
    call Timer0.startOneShot(SHORT_DELAY * 10);
    post sendPayload();
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    if (err == SUCCESS) {
      drop_message(msg);
      counter++;


//        dbg("Application", "Application got send done\n");
      if (QUICK == 1) {
        call Timer0.startOneShot(SHORT_DELAY * 10);
        post sendPayload();
      }
    } else {
      dbg("Application", "Application: Send done failed\n");
      drop_message(msg);
      call Timer0.startOneShot(SHORT_DELAY);
    }
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    nx_struct payload_msg *c = (nx_struct payload_msg*)payload;
    dbg("Application", "Receive message counter %d total size %d\n", c->counter, size);

    if (c->counter % 100 == 0) {

      uint16_t n = call Timer0.getNow();
      uint8_t *p = (uint8_t*)&n;
      
      serialSend(F_APPLICATION, 0, p[0], p[1], 2, c->counter);
      call Leds.set(c->counter);
    }
    drop_message(msg);
  }

}
