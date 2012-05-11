#include <Fennec.h>
#include "SendTempHumLightApp.h"

generic module SendTempHumLightAppP(uint16_t delay, uint16_t root) {

  provides interface Mgmt;
  provides interface Module;

  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as Temperature;
  uses interface Read<uint16_t> as Humidity;
  uses interface Read<uint16_t> as Light;

  uses interface Serial;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter = 0;
  msg_t* message;
  env_msg_t *thl_m;

  command error_t Mgmt.start() {
    if (TOS_NODE_ID != root) {
      call Timer0.startPeriodic(delay);
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

  event void Timer0.fired() {
    counter = (counter + 1) % 2000;
    call Leds.set(counter);
    if (call Temperature.read() != SUCCESS) {

    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, 
						uint8_t size) {
    if (TOS_NODE_ID == root) {
      env_msg_t *m = (env_msg_t*)payload;
      call Leds.set(m->counter);

      //printf("Received msg # %d: temp %d, humidity %d, light %d\n", m->counter, m->temp, m->hum, m->light);
      call Serial.send(payload, size);
    }
    signal Module.drop_message(msg);
  }

  event void Temperature.readDone( error_t result, uint16_t val ) {
    if ((TOS_NODE_ID != root) && (result == SUCCESS)) {
      message = signal Module.next_message();

      if (message == NULL) return;

      thl_m = (env_msg_t*) call NetworkCall.getPayload(message);
      thl_m->counter = counter;
      thl_m->temp = val;
      call Humidity.read();
    } else {
      signal Module.drop_message(message);
    }
  }

  event void Humidity.readDone( error_t result, uint16_t val ) {
    if ((TOS_NODE_ID != root) && (result == SUCCESS)) {
      thl_m->hum = val;
      call Light.read();
    } else {
      signal Module.drop_message(message);
    }
  }

  event void Light.readDone( error_t result, uint16_t val ) {
    if ((TOS_NODE_ID != root) && (result == SUCCESS)) {
      thl_m->light = val;
      thl_m->node = TOS_NODE_ID;
      message->len = sizeof(env_msg_t);
      message->next_hop = root;
      if ((call NetworkCall.send(message)) != SUCCESS) {
        signal Module.drop_message(message);
      }
    } else {
      signal Module.drop_message(message);
    }
  }

  event void Serial.receive(void *buf, uint16_t len) {

  }
}
