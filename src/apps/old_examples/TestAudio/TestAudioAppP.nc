/*
 * Application: 
 * Author: 
 * Date: 
 */

#include <Fennec.h>
#include "TestAudioApp.h"
#include "intel16.h"


generic module TestAudioAppP() {

  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface NetworkCall;
  uses interface NetworkSignal;
  uses interface Timer<TMilli> as Timer0;

  uses interface Audio;
}

implementation {

  command error_t Mgmt.start() {

    call Leds.led2On();
    call Audio.playStream(pcmdata, pcmdatalen);
    call Leds.led2Off();

    call Timer0.startPeriodic(1024*15);
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
    call Leds.led0On();
    call Audio.readStream(intel_song, SOUND_BUFFER_LENGTH);
    call Leds.led0Off();

    call Leds.led1On();    
    call Audio.playStream(intel_song, SOUND_BUFFER_LENGTH);
    call Leds.led1Off();
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {

    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, 
						uint8_t size) {

    signal Module.drop_message(msg);
  }

}

