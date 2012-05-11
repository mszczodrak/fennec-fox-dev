/*
 * Application: 
 * Author: 
 * Date: 
 */

#include <Fennec.h>
#include "RssiLqiApp.h"

#define LQI_SRC 	1
#define LQI_DST		0

generic module RssiLqiAppP() {

  provides interface SplitControl;
  uses interface Leds;
  uses interface NetworkCall;
  uses interface NetworkSignal;
  uses interface Timer<TMilli> as Timer0;

}

implementation {

  uint16_t counter;

  command error_t SplitControl.start() {
    counter = 0;

    if (TOS_NODE_ID == LQI_SRC) {
      call Timer0.startPeriodic(1024);
      setFennecStatus( F_DATA_SRC, ON );
    }

    if (TOS_NODE_ID == LQI_DST) {
      setFennecStatus( F_BRIDGING, ON );
#ifndef TOSSIM
      setFennecStatus( F_PRINTING, ON );
#endif
    }

    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    
    if (TOS_NODE_ID == LQI_SRC) {
      setFennecStatus( F_DATA_SRC, OFF );
    }

    if (TOS_NODE_ID == LQI_DST) {
      setFennecStatus( F_BRIDGING, OFF );
#ifndef TOSSIM
      setFennecStatus( F_PRINTING, OFF );
#endif
    }

    call Timer0.stop();
    call Leds.set(0);
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    msg_t *m = nextMessage();
    rssilqi_msg_t *r_m = (rssilqi_msg_t*) call NetworkCall.getPayload(m);
    counter++;
    call Leds.set(counter);
    r_m->counter = counter;

    m->len = sizeof(rssilqi_msg_t);
    m->next_hop = LQI_DST;
    call NetworkCall.send(m);
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    rssilqi_msg_t *r_m = (rssilqi_msg_t*) payload;
    call Leds.set(r_m->counter);
    printf("[%d]  Lqi: %d   Rssi: %d\n", r_m->counter, msg->lqi, msg->rssi);
    printfflush();
    drop_message(msg);
  }

}
