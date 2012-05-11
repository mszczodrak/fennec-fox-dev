
module ms320_lpP {
  provides interface SplitControl;
  provides interface Read<uint16_t>;
  
  uses interface Leds;
  uses interface GeneralIO as PresencePin;
  uses interface Timer<TMilli> as PIRTimer;
}
implementation {

  enum {
	S_STARTED,
	S_STOPPED,
  };

  uint8_t state = S_STOPPED;

  command error_t SplitControl.start(){
    if(state == S_STOPPED){
      call PresencePin.makeInput();
      call PIRTimer.startOneShot(256);
      return SUCCESS;
    }
    return FAIL;
  }

  command error_t SplitControl.stop(){
    if(state == S_STARTED){
      call PresencePin.makeOutput();
      call PresencePin.clr();
      call PIRTimer.startOneShot(256);
      return SUCCESS;
    }
    return FAIL;
  }

  event void PIRTimer.fired(){
    if(state == S_STOPPED){
      state = S_STARTED;
      signal SplitControl.startDone(SUCCESS);
    } else if(state == S_STARTED) {
      state = S_STOPPED;
      signal SplitControl.stopDone(SUCCESS);
    }
  }

  command error_t Read.read() {
    if(call PresencePin.get()) {
      signal Read.readDone(SUCCESS, 0);
    } else {
      signal Read.readDone(SUCCESS, 1);
    }
    return SUCCESS;
  }

}


