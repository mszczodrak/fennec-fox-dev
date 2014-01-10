#include <Fennec.h>
#include "DebugMsg.h"

module FennecSerialDbgP @safe() {
  provides interface SimpleStart;

#ifdef __DBGS__
  uses interface SplitControl;
  uses interface Receive;
  uses interface AMSend;
  uses interface Queue<nx_struct debug_msg>;
#endif
  uses interface Leds;
}

implementation {

uint8_t state = S_STOPPED;

#ifdef __DBGS__
message_t packet;
norace nx_struct debug_msg *msg;
#endif

command void SimpleStart.start() {
	state = S_STOPPED;
#ifdef __DBGS__
	state = S_STARTING;
	msg = NULL;
	call SplitControl.start();
#endif
	signal SimpleStart.startDone(SUCCESS);
}

#ifdef __DBGS__
task void send_msg() {
	if (state == S_STARTED) {
		nx_struct debug_msg q_msg = call Queue.dequeue();
		state = S_TRANSMITTING;
		memcpy(msg, &q_msg, sizeof(nx_struct debug_msg));
		call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(nx_struct debug_msg));
	}
}

event message_t* Receive.receive(message_t* bufPtr,
                                   void* payload, uint8_t len) {
	return bufPtr;
}

event void AMSend.sendDone(message_t* bufPtr, error_t error) {
	state = S_STARTED;
	if (call Queue.empty()) {
	} else {
		post send_msg();
	}
}

event void SplitControl.startDone(error_t err) {
	state = S_STARTED;
	msg = (nx_struct debug_msg*) call AMSend.getPayload(&packet, sizeof(nx_struct debug_msg));
}

event void SplitControl.stopDone(error_t err) {

}
#endif

bool dbgs(uint8_t layer, uint8_t dbg_state, uint16_t action, uint16_t d0, uint16_t d1) @C() {
	dbg("Dbgs", "Dbgs 0x%1x 0x%1x 0x%1x 0x%1x 0x%1x", layer, dbg_state, action, d0, d1);
#ifdef __DBGS__
	atomic {
		if (call Queue.full()) 
			return 1;

		memset(msg, 0, sizeof(nx_struct debug_msg));
		msg->layer = layer;
		msg->state = dbg_state;
		msg->action = action;
		msg->d0 = d0;
		msg->d1 = d1;
		call Queue.enqueue(*msg);

		post send_msg();
	}
#endif
	return 0;
}

}

