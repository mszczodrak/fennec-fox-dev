/*
 *  lpl radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Application: LPL Radio Module
 * Author: Marcin Szczodrak
 * Date: 10/12/2011
 * Last Modified: 2/6/2012
 */

#include <Fennec.h>
#include <lplRadio.h>

generic module lplRadioP(uint16_t sleep_time, uint16_t active_time, uint16_t stay_awake_time) @safe() {
  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;

  uses interface Mgmt as CC2420Mgmt;
  uses interface RadioCall as CC2420RadioCall;
  uses interface RadioSignal as CC2420RadioSignal;
  uses interface Timer<TMilli> as AwakeTimer;
  uses interface Timer<TMilli> as PreambleTimer;
  uses interface Timer<TMilli> as Timer;
  uses interface Timer<TMilli> as Receiver;
  uses interface Random;
}


implementation {

  uint8_t radio_state = S_STOPPED;
  msg_t *waiting_to_send;
  msg_t *preamble_msg;

  uint8_t loaded_awake_delay;
  uint16_t checks;
  uint16_t detections;

  void send_preamble(void);
  void send_preamble_reply(void);
  void signal_fail(void);
  void check_channel_status(void);
  
  task void channel_status(void);

  uint8_t *getRadioPayload(msg_t* msg);

  uint16_t last_addr;

  void clear_preamble_msg(void) {
    if (preamble_msg != NULL) {
      //dbg("Radio", "Radio LPL drop_message for preamble\n");
      signal Module.drop_message(preamble_msg);
      preamble_msg = NULL;
    }
  }

  error_t goto_operational() {
    radio_state = S_OPERATIONAL;
    call Timer.stop();
    clear_preamble_msg();
    //dbg("Radio", "Radio LPL radio_state becomes S_OPERATIONAL\n");
    return SUCCESS;
  }

  task void load_data_message() {
    dbg("Radio", "Radio LPL load_data_message\n");
    radio_state = S_TRANSMITTING;
    if (call CC2420RadioCall.load(waiting_to_send) != SUCCESS) {
      dbg("Radio", "Radio LPL load_data_message - FAILED\n");
      signal_fail();
    }
  }

  task void send_data_message() {
    dbg("Radio", "Radio LPL send_data_message\n");
    if (call CC2420RadioCall.send(waiting_to_send) != SUCCESS) {
      dbg("Radio", "Radio LPL send_data_message - FAILED\n");
      signal_fail();
    }
  }

  task void set_next_preamble_transmission() {
    uint16_t resend_delay = min(active_time / PREAMBLE_RESEND_FREQUENCY, PREAMBLE_MAX_RESEND_DELAY);
    //dbg("Radio", "Radio LPL - preamble will be send in %d ms\n", resend_delay);
    call Timer.startOneShot(resend_delay);
  }

  task void update_receiver() {
    //dbg("Radio", "Radio LPL Receiver %d will fire in %d ms\n", last_addr, stay_awake_time);
    call Receiver.startOneShot(stay_awake_time);
  }

  task void update_awake() {
    //dbg("Radio", "Radio LPL Increases AwakeTimer by %d\n", stay_awake_time);
    call AwakeTimer.startOneShot(stay_awake_time);
  }
 
  command error_t Mgmt.start() {
    waiting_to_send = NULL;
    preamble_msg = NULL;
    radio_state = S_SLEEPING;
    //dbg("Radio", "Radio LPL radio_state becomes S_SLEEPING\n");
    signal Mgmt.startDone(SUCCESS);
    call AwakeTimer.startOneShot(sleep_time);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    if (radio_state == S_STOPPED) {
      signal Mgmt.stopDone(SUCCESS);
    } else {
      if (call CC2420Mgmt.stop() == SUCCESS) {
        //dbg("Radio", "Radio LPL radio_state becomes S_STOPPING\n");  
        radio_state = S_STOPPING;
      } else {
        signal Mgmt.stopDone(FAIL); 
      }
    }
    clear_preamble_msg();
    return SUCCESS;
  }

  command error_t RadioCall.send(msg_t *msg) {
    //printf("Radio start\n");

    if ((waiting_to_send != msg) || (waiting_to_send == NULL)) {
      //dbg("Radio", "Radio LPL got send - problem with waitin_to_send\n");
      return FAIL;
    }

    if (radio_state != S_OPERATIONAL) {
      dbg("Radio", "Radio LPL got send - is not operational\n");
      return FAIL;
    }

    post update_awake();

    /* if it is an ASAP, attempt to send immediatelly */
    if (msg->asap == ON) {
      post load_data_message();
      return SUCCESS;
    }

    if ((call Receiver.isRunning()) && ((last_addr == BROADCAST) || (last_addr == msg->next_hop))) {
      dbg("Radio", "Radio LPL got send: right away - last_addr %d, msg addr %d\n", last_addr, msg->next_hop);
      last_addr = msg->next_hop;
      post load_data_message();
      post update_receiver();
      return SUCCESS;
    }

    last_addr = msg->next_hop;
    call Receiver.stop();

    /* OK, first wakeup the other guys */
    //dbg("Radio", "Radio LPL send - start with preamble\n");
    radio_state = S_PREAMBLE;
    dbg("Radio", "Radio LPL radio_state becomes S_PREAMBLE\n");
    call PreambleTimer.startOneShot(sleep_time);
    call Timer.startOneShot(active_time / 4);
    return SUCCESS;
  }

  command error_t RadioCall.resend(msg_t *msg) {
    if (waiting_to_send && msg != waiting_to_send) 
      return FAIL;
    return call CC2420RadioCall.resend(msg);
  }

  command uint8_t RadioCall.getMaxSize(msg_t *msg) {
    return call CC2420RadioCall.getMaxSize(msg) - (sizeof(nx_struct lpl_header) 
					- sizeof(nx_struct fennec_header));
  }

  command uint8_t* RadioCall.getPayload(msg_t *msg) {
    uint8_t *m = call CC2420RadioCall.getPayload(msg);
    if (m == NULL) return NULL;
    m += (sizeof(nx_struct lpl_header) - sizeof(nx_struct fennec_header));
    
    return m;
  }

  command error_t RadioCall.load(msg_t *msg) {
    nx_struct lpl_header *lpl = (nx_struct lpl_header*) 
					call CC2420RadioCall.getPayload(msg);
    //dbg("Radio", "Radio LPL got load - state %d\n", radio_state);

    /* Is there already a message ready to be send */
    if (waiting_to_send != NULL) {
      //dbg("Radio", "Radio LPL got load return FAIL because waiting_to_send != NULL\n");
      return FAIL;
    }

    /* check radio states */
    if ((radio_state != S_SLEEPING) && (radio_state != S_OPERATIONAL)) {
      dbg("Radio", "Radio LPL got load return FAIL because of state %d\n", radio_state);
      return FAIL;
    }

    lpl->lpl = LPL_DATA;
    msg->len = msg->len + (sizeof(nx_struct lpl_header) - sizeof(nx_struct fennec_header));
    msg->fennec.len = msg->len;
    lpl->fennec.len = msg->len;

    waiting_to_send = msg;
    loaded_awake_delay = 0;

    switch(radio_state) {
      case S_SLEEPING:  
        /* Need to start radio before we load message */
        signal AwakeTimer.fired();
        break;

      case S_OPERATIONAL:
        post update_awake();
        signal RadioSignal.loadDone(msg, SUCCESS);
        break;
  
      default:
        dbg("Radio", "Radio LPL load should not be here\n");
    }
    return SUCCESS;
  }

  command uint8_t RadioCall.sampleCCA(msg_t *msg) {
    return call CC2420RadioCall.sampleCCA(msg);
  }

  command error_t RadioCall.cancel(msg_t *msg) {
    switch(radio_state) {
      case S_STOPPED:
      case S_STOPPING:
      case S_TURN_OFF:
      case S_TURN_ON:
        break;

      default:
        if (waiting_to_send != NULL) {
          call CC2420RadioCall.cancel(msg);
          waiting_to_send = NULL;
          goto_operational();
        }
    }
    return SUCCESS;
  }

  event void CC2420Mgmt.startDone(error_t status) {
    //dbg("Radio", "Radio LPL CC2420Mgmt.startDone\n");
    switch(radio_state) {
      case S_TURN_ON:
	/* Radio is ON because.. */
        dbg("Radio", "Radio LPL radio_state becomes S_OPERATIONAL after startDone\n");
        radio_state = S_OPERATIONAL;
        preamble_msg = NULL;
        if (waiting_to_send) {
          post update_awake();
          /* we actually have a message to send
	   * but, that's it for know, say the load done */
          signal RadioSignal.loadDone(waiting_to_send, SUCCESS);
        } else {
          call AwakeTimer.startOneShot(active_time);
	  /* timer fired so check if there are any preambles in the air */
	  //dbg("Radio", "Radio LPL CC2420Mgmt.startDone - start checking channel status\n");
  	  check_channel_status();
        }
        break;

      default:
        dbg("Radio", "Radio LPL CC2420Mgmt.startDone started, but why?\n");
    }
  }

  event void CC2420Mgmt.stopDone(error_t status) {
    dbg("Radio", "Radio LPL CC2420Mgmt.stopDone\n");
    switch(radio_state) {
      case S_STOPPING:
        /* This is Module-wise turn off */
        dbg("Radio", "Radio LPL radio_state becomes S_STOPPED\n");
        radio_state = S_STOPPED;
        signal Mgmt.stopDone(status);
        break;

      case S_TURN_OFF:
        /* Going to Sleep */
        dbg("Radio", "Radio LPL radio_state becomes S_SLEEPING\n");
        if (waiting_to_send != NULL) {
          signal_fail();
        }
        goto_operational();
        radio_state = S_SLEEPING;
        call AwakeTimer.startOneShot(sleep_time);
        break;

      default:
        /* should not be here */
        break;
    }
  }

  event void CC2420RadioSignal.sendDone(msg_t *msg, error_t err) {
    /* something is going on so stay awake */
    //dbg("Radio", "Radio LPL sendDone - stay awake\n");
    post update_awake();

    switch(radio_state) {
      case S_PREAMBLE:
        if (call PreambleTimer.isRunning()) {
          post set_next_preamble_transmission();
        } else {
          dbg("Radio", "Radio LPL Signal.sendDone - No more preamble resends\n");
          post update_receiver();
          post load_data_message();
        }
        if (msg != preamble_msg) {
          signal Module.drop_message(msg);
        }
        clear_preamble_msg();
        break;


      case S_TRANSMITTING:
        radio_state = S_OPERATIONAL;
        if (msg->asap != ON) {
          post update_receiver();
        }
        waiting_to_send = NULL;
        signal RadioSignal.sendDone(msg, err);
        break;

      case S_SENDING_ACK:
        goto_operational();
        break;

      default:
        //dbg("Radio", "Radio LPL sendDone - default\n");
        signal Module.drop_message(msg);
        dbg("Radio", "Radio: Got sendDone but in state %d\n", radio_state);
    }
  }

  event void CC2420RadioSignal.loadDone(msg_t *msg, error_t err) {
    /* something is going on so stay awake */
    //dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - stay awake\n");
    post update_awake();

    switch(radio_state) {
      case S_TRANSMITTING:
        if (err != SUCCESS) {
          dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - faile send waiting_to_send message\n");
          signal_fail();
        } else {
          //dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - S_OPERATIONAL, sending waiting_to_send message\n");
          post send_data_message();
        }
        break;

      case S_PREAMBLE:
        if (err != SUCCESS) {
          dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - faile send PREAMBLE\n");
          signal_fail();
        } else {
          //dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - S_PREAMBLE, send it rigth away\n");
          if (call CC2420RadioCall.send(msg) != SUCCESS) {
            dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - S_PREAMBLE, send it rigth away - FAILED\n");
            clear_preamble_msg();
          }
        }
        break;

      case S_SENDING_ACK:
        //dbg("Radio", "Radio load Done send ACK\n");
        //dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - S_SENDING_ACK - send it right away\n");
        if (call CC2420RadioCall.send(msg) != SUCCESS) {
          clear_preamble_msg();
        }
        break;

      default: 
        dbg("Radio", "Radio LPL CC2420RadioSignal.loadDone - default - signal loadDone\n");
        signal RadioSignal.loadDone(msg, err);
    }
  }

  event void CC2420RadioSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    nx_struct lpl_header *header = (nx_struct lpl_header*)payload;
    post update_awake();

    if ((msg == NULL) || (payload == NULL)) {
      signal Module.drop_message(msg);
      return;
    }

    /* Check if the receiver is still up */
    if (last_addr == header->from) {
      post update_receiver(); 
    }

    switch(radio_state) {
      case S_TRANSMITTING:
        switch(header->lpl) {
          case LPL_DATA:
            //dbg("Radio", "Radio LPL receive LPL_DATA while in S_OPERATIONAL\n");
            goto signal_receive;
            break;
        }
        break;

      case S_OPERATIONAL:
        switch(header->lpl) {
          case LPL_DATA:
            //dbg("Radio", "Radio LPL receive LPL_DATA while in S_OPERATIONAL\n");
            goto signal_receive;
            break;

          case LPL_WAKEUP:
            if (header->dest == BROADCAST) {
              /* OK, BROADCAST is in the air, but let it go
               * all preambles to BROADCAST address run complete *sleep_time*
               * cycle - you're awake, but others may be still asleep
               */
              break;
            }

            if (header->dest == TOS_NODE_ID) {
              /* Receiver header to this node, reply to speed-up transmission */
              radio_state = S_SENDING_ACK;
              dbg("Radio", "Radio LPL receive Received LPL_WAKEUP to %d\n", header->dest);
              send_preamble_reply();
              break;
            }

            if ((waiting_to_send == NULL) && (preamble_msg == NULL)) {
              /* At this point this preamble is to someone else, so we could go sleep ? */
              /* how about, dest LPL_PREAMBLE after BROADCAST PREABLE ?? */
              //signal AwakeTimer.fired();
            }
            break;

          case LPL_WAKEUP_ACK:
            //dbg("Radio", "Radio LPL receive LPL_WAKEUP_ACK while in S_OPERATIONAL - ignore\n");
            break;
          default:
            //dbg("Radio", "Radio LPL receive something while in S_OPERATIONAL????\n");
            break;
        }
        break;

      case S_PREAMBLE:
        switch(header->lpl) {
          case LPL_DATA:
            /* check if data arrived from a node we are waiting to get an ACK from */
            if ((waiting_to_send != NULL) && (waiting_to_send->next_hop != BROADCAST) &&
              (waiting_to_send->next_hop == header->dest)){
              /* This LPL_DATA transmission should be concidred as LPL_WAIT_ACK */
              dbg("Radio", "Radio LPL received LPL_ACK sent as LPL_DATA\n");
              call PreambleTimer.startOneShot(0);
            }
            goto signal_receive;

          case LPL_WAKEUP:
            if (waiting_to_send == NULL) {
              /* This should not happen, being in S_PREAMBLE should guarantee 
               * that *waiting_to_send* is not NULL
               */
              dbg("Radio", "Radio LPL error 1\n");
              break;
            }
        
            /* Receive LPL_WAKEUP from the destination we plan to send a message to */ 
            if (waiting_to_send->next_hop == header->from) {
              dbg("Radio", "Radio LPL received LPL_ACK sent as LPL_WAKEUP\n");
              call PreambleTimer.startOneShot(0);
              break;
            }

            /* Are we sending preamble to BROADCAST, try to optimize */ 
            if (waiting_to_send->next_hop == BROADCAST) {
              /* Use someone's else preamble as your own preamble, so delay yours */
              if (call Timer.isRunning()) {
                post set_next_preamble_transmission();
              }
              break;
            }

          case LPL_WAKEUP_ACK:
            if (waiting_to_send->next_hop == header->from) {
              dbg("Radio", "Radio LPL received LPL_WAKEUP_ACK - was waiting for it!\n");
              call PreambleTimer.startOneShot(0);
              break;
            }
            break;
        }
        break;

      default:
        dbg("Radio", "Radio LPL receive something while in state %d\n", radio_state);
        break;
    }
    signal Module.drop_message(msg);
    return;

signal_receive:
    //dbg("Radio", "Radio LPL signal message receive\n");
    payload += (sizeof(nx_struct lpl_header) - sizeof(nx_struct fennec_header));
    len -= (sizeof(nx_struct lpl_header) - sizeof(nx_struct fennec_header));
    msg->len = len;
    signal RadioSignal.receive(msg, payload, len);
  }

  async event bool CC2420RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    nx_struct lpl_header *lpl = (nx_struct lpl_header*) payload;
    //dbg("Radio", "Radio calls check destination\n");

    if (payload == NULL) return FALSE;

    switch(lpl->lpl) {
      case LPL_DATA:
        return signal RadioSignal.check_destination(msg, payload + 
			(sizeof(nx_struct lpl_header) - sizeof(nx_struct fennec_header)));

      case LPL_WAKEUP:
      case LPL_WAKEUP_ACK:
        return TRUE;

      default:
        dbg("Radio", "Radio here??\n");
        return FALSE;
    }
  }

  event void PreambleTimer.fired() {
    if (call Timer.isRunning()) {
      call Timer.stop(); 
      //dbg("Radio", "Radio LPL PreambleTimer fired - sendData\n");
      post update_receiver();
      post load_data_message();
    } else {
      dbg("Radio", "Radio LPL PreambleTimer fired - skip\n");
    }
  }

  event void Receiver.fired() {
    dbg("Radio", "Radio LPL Receiver fired\n");
  }

  event void AwakeTimer.fired() {
    //dbg("Radio", "Radio LPL AwakeTimer.fired\n");
    call Timer.stop();

    if (call Receiver.isRunning()) {
      call AwakeTimer.startOneShot(active_time);
      return;
    }

    switch(radio_state) {
      case S_SLEEPING:
        //dbg("Radio", "Radio: AwakeTimer.fired - starting radio\n");
        //dbg("Radio", "Radio LPL radio_state becomes S_TURN_ON\n");
        radio_state = S_TURN_ON;
        call CC2420Mgmt.start();
        break;

      case S_TRANSMITTING:
      case S_OPERATIONAL:
        if ((waiting_to_send != NULL) && (++loaded_awake_delay <= LOADED_MESSAGE_AWAKE_DELAY)) {
          //dbg("Radio", "Radio LPL AwakeTimer.fired stay on since loaded_awake\n");
          call AwakeTimer.startOneShot(active_time);
          break;
        }
      case S_SENDING_ACK:
      case S_PREAMBLE:
        //dbg("Radio", "Radio LPL AwakeTimer.fired go to TURN_OFF\n");
        //dbg("Radio", "Radio LPL radio_state becomes S_TURN_OFF\n");
        call PreambleTimer.stop();
        radio_state = S_TURN_OFF;
        if (waiting_to_send != NULL) {
          //dbg("Radio", "Radio LPL AwakeTimer.fired signals sendDone FAIL\n");
          signal RadioSignal.sendDone(waiting_to_send, FAIL);
          waiting_to_send = NULL;
        }
        //dbg("Radio", "Radio LPL AwakeTimer.fired call CC2420Mgmt.stop\n");
        call CC2420Mgmt.stop();
        break;

      default:
        dbg("Radio", "Radio LPL AwakeTimer.fired should not be here, is at %d\n", radio_state);
    }
  }


  event void Timer.fired() {
    //dbg("Radio", "Radio LPL Timer.fired\n");
    switch(radio_state) {
      case S_PREAMBLE:
        send_preamble();
        break;

      case S_SENDING_ACK:
        //dbg("Radio", "Radio Timer -> sending ACK\n");
	//printf("SEND ACK\n");
	send_preamble_reply();
        break;

      default:
        dbg("Radio", "Radio: well - let it goi - in state %d\n", radio_state);
        /* should not be here */
        break;
    }
  }


  void signal_fail() {
    //dbg("Radio", "Radio LPL signals_fail\n");
    signal Module.drop_message(preamble_msg);
    signal RadioSignal.loadDone(waiting_to_send, FAIL);
    waiting_to_send = NULL;
    //dbg("Radio", "Radio LPL radio_state becomes S_OPERATIONAL\n");
    goto_operational();
    //signal AwakeTimer.fired();
  }


  void send_preamble(void) {
    /* We need to start with preamble first */
    nx_struct lpl_header *header;

    clear_preamble_msg();

    //dbg("Radio", "Radio LPL next_message for preamble\n");
    preamble_msg = signal Module.next_message();
    if (preamble_msg == NULL) {
      signal_fail();
      return;
    }

    header = (nx_struct lpl_header*) call CC2420RadioCall.getPayload(preamble_msg);

    if (header == NULL) {
      signal_fail();
      return;
    }

    header->lpl = LPL_WAKEUP;
    header->dest = waiting_to_send->next_hop;
    header->from = TOS_NODE_ID;
    preamble_msg->len = sizeof(nx_struct lpl_header);
    preamble_msg->fennec.len = sizeof(nx_struct lpl_header);
    header->fennec.len = sizeof(nx_struct lpl_header);

    if (call CC2420RadioCall.load(preamble_msg) != SUCCESS) {
      signal_fail();
    }
  }


  void send_preamble_reply(void) {
    /* We need to start with preamble first */
    nx_struct lpl_header *lpl;

    clear_preamble_msg();

    preamble_msg = signal Module.next_message();
    if (preamble_msg == NULL) {
      clear_preamble_msg();
      return;
    }

    dbg("Radio", "Radio LPL next_message for preamble reply\n");

    lpl = (nx_struct lpl_header*) call CC2420RadioCall.getPayload(preamble_msg);

    if (lpl == NULL) {
      clear_preamble_msg();
      return;
    }

    lpl->lpl = LPL_WAKEUP_ACK;
    lpl->dest = TOS_NODE_ID;
    lpl->from = TOS_NODE_ID;
    preamble_msg->len = sizeof(nx_struct lpl_header);
    preamble_msg->fennec.len = sizeof(nx_struct lpl_header);
    lpl->fennec.len = sizeof(nx_struct lpl_header);

    if (call CC2420RadioCall.load(preamble_msg) != SUCCESS) {
      clear_preamble_msg();
    }
  }

  void check_channel_status() {
    detections = 0;
    checks = MAX_LPL_CCA_CHECKS;
    post channel_status();
  }

  task void channel_status() {
    detections += !call CC2420RadioCall.sampleCCA(NULL);
    if (--checks) {
      post channel_status();
    } else {
      if (detections >= MIN_CCA_SAMPLE_TO_DETECT) {
        dbg("Radio", "Radio: detected energy, stay on: detections: %d\n", detections);
        //dbg("Radio", "Radio keep active: 451\n");
        call Timer.startOneShot(active_time);
      } else {
        //dbg("Radio", "Radio: nothing on the channel, go sleep: detections: %d\n", detections);
      }
    }
  }

}

