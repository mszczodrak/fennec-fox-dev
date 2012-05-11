#include <Fennec.h>

module FennecP {
  uses interface Boot;

  uses interface SimpleStart as DbgSerial;
  uses interface SimpleStart as RandomStart;
  uses interface SimpleStart as Caches;
  uses interface SimpleStart as PolicyStart;
}

implementation {

  event void Boot.booted() {
    dbg("Fennec", "Fennec Boot.booted() -> DbgSerial.start()\n");
    call DbgSerial.start();
  }

  event void DbgSerial.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("Fennec", "Fennec DbgSerial.startDone() -> RandomStart.start()\n");
      call RandomStart.start();
    } else {
      dbg("Fennec", "Fennec DbgSerial.startDone() -> DbgSerial.start()\n");
      call DbgSerial.start();
    }
  }

  event void RandomStart.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("Fennec", "Fennec RandomStart.startDone() -> Caches.start()\n");
      call Caches.start();
    } else {
      dbg("Fennec", "Fennec RandomStart.startDone() -> RandomStart.start()\n");
      call RandomStart.start();
    }
  }

  event void Caches.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("Fennec", "Fennec Caches.startDone() -> PolicyStart.start()\n");
      call PolicyStart.start();
    } else {
      dbg("Fennec", "Fennec Caches.startDone() -> Caches.start()\n");
      call Caches.start();
    }
  }

  event void PolicyStart.startDone(error_t err) {
      dbg("Fennec", "PolicyStart.startDone()\n");
  }

}

