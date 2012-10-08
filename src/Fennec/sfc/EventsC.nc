
#include <Fennec.h>

configuration EventsC {
  provides interface Mgmt;
}

implementation {

  components EventsP;
  Mgmt = EventsP;

  components CachesC;
  EventsP.EventCache -> CachesC;
  /* Defined and linked event handlers */

  components new TimerEventC() as TimerEvent1C;
  EventsP.TimerEvent1 -> TimerEvent1C;

  components new TimerEventC() as TimerEvent2C;
  EventsP.TimerEvent2 -> TimerEvent2C;

  components new TimerEventC() as TimerEvent3C;
  EventsP.TimerEvent3 -> TimerEvent3C;

}
