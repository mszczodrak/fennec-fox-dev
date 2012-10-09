
#include <Fennec.h>

module EventsP {

  provides interface Mgmt;
  uses interface EventCache;
  uses interface Event as TimerEvent1;
  uses interface Event as TimerEvent2;

}

implementation {

  void turnEvents(bool flag);
  void setEvent(uint8_t ev_num, bool flag);

  command error_t Mgmt.start() {
    turnEvents(ON);
    dbg("Events", "Events started\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    turnEvents(OFF);
    dbg("Events", "Events stopped\n");
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  void turnEvents(bool flag) {
    uint8_t i;
    for(i = 0 ; i < 2; i++ ) {
      if ( call EventCache.eventStatus(i)) {
        setEvent(i + 1, flag);
      }
    }
  }

  void setEvent(uint8_t ev_num, bool flag) {

    switch(ev_num) {

      case 0:
        break;

      case 1:
        flag ? call TimerEvent1.start(call EventCache.getEntry(1)) : call TimerEvent1.stop();
        break;

      case 2:
        flag ? call TimerEvent2.start(call EventCache.getEntry(2)) : call TimerEvent2.stop();
        break;

      default:
        dbg("Events", "Events: there is no event with number %d\n", ev_num);
    }
  }

  event void TimerEvent1.occured(bool oc) {
    oc ? call EventCache.setBit(1) : call EventCache.clearBit(1);
  }

  event void TimerEvent2.occured(bool oc) {
    oc ? call EventCache.setBit(2) : call EventCache.clearBit(2);
  }


}
