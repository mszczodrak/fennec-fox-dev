#include <Fennec.h>
#include "DebugMsg.h"

module FennecSerialDbgP {
  provides interface SimpleStart;

#ifdef __DBGS__
  uses interface SplitControl;
  uses interface Receive;
  uses interface AMSend;
  uses interface Queue<nx_struct debug_msg>;
#endif
}

implementation {

#ifdef __DBGS__
  message_t packet;
  nx_struct debug_msg *msg;
  bool busy;
#endif

  command void SimpleStart.start() {
#ifdef __DBGS__
    msg = NULL;
    busy = FALSE;
    call SplitControl.start();
#else
    signal SimpleStart.startDone(SUCCESS);
#endif
  }

#ifdef __DBGS__
  event message_t* Receive.receive(message_t* bufPtr,
                                   void* payload, uint8_t len) {
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (call Queue.empty()) {
      busy = 0;
    } else {
      nx_struct debug_msg q_msg = call Queue.dequeue();
      memcpy(msg, &q_msg, sizeof(nx_struct debug_msg));
      call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(nx_struct debug_msg));
    }
  }

  event void SplitControl.startDone(error_t err) {
    msg = (nx_struct debug_msg*) call AMSend.getPayload(&packet, sizeof(nx_struct debug_msg));
    signal SimpleStart.startDone(SUCCESS);
  }

  event void SplitControl.stopDone(error_t err) {}
#endif

  bool dbgs(uint8_t layer, uint8_t state, uint16_t action, uint16_t d0, uint16_t d1) @C() {
#ifdef __DBGS__
    if (call Queue.full()) 
      return 1;

    memset(msg, 0, sizeof(nx_struct debug_msg));
    msg->layer = layer;
    msg->state = state;
    msg->action = action;
    msg->d0 = d0;
    msg->d1 = d1;

    if (busy) {
      call Queue.enqueue(*msg);
    } else {
      busy = 1;
      call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(nx_struct debug_msg));
    }
#endif

    return 0;
  }
}

