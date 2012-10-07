
#include <Fennec.h>

module EventsP {

  provides interface Mgmt;
  uses interface EventCache;

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
    for(i = 0 ; i < 0; i++ ) {
      if ( call EventCache.eventStatus(i)) {
        setEvent(i + 1, flag);
      }
    }
  }

  void setEvent(uint8_t ev_num, bool flag) {

    switch(ev_num) {

      case 0:
        break;

      default:
        dbg("Events", "Events: there is no event with number %d\n", ev_num);
    }
  }


}
