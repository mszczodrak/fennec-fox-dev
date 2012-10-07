
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

}
