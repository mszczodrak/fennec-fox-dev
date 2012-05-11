/*
 *  simpleCC2420 radio module for Fennec Fox platform.
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
 * Application: Radio Module for CC2420
 * Author: Marcin Szczodrak
 * Date: 9/29/2009
 * Last Modified: 2/9/2012
 */

/*
 * Based on Jonathan Hui CC2420 driver implementation for TinyOS
 */

#include <Fennec.h>
#include "CC2420.h"
#include "IEEE802154.h"
#include "simpleCC2420Radio.h"

generic module simpleCC2420RadioP(uint8_t radio_channel, uint8_t tx_power, bool enable_auto_crc) @safe() {

  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;

  uses interface Alarm<T32khz,uint32_t> as StartupTimer;

  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as SFD;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;
  uses interface GpioInterrupt as InterruptCCA;

  uses interface Resource as SpiResource;

  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;
  uses interface CC2420Strobe as SFLUSHTX;

  uses interface CC2420Strobe as SRXDEC;
  uses interface CC2420Register as SECCTRL0;
  uses interface CC2420Register as SECCTRL1;
  uses interface CC2420Ram as KEY0;
  uses interface CC2420Ram as KEY1;
  uses interface CC2420Ram as RXNONCE;
  uses interface CC2420Ram as RXFIFO_RAM;
  uses interface CC2420Strobe as SNOP;

  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as STXON;

  uses interface CC2420Register as FSCTRL;
  uses interface CC2420Register as IOCFG0;
  uses interface CC2420Register as IOCFG1;
  uses interface CC2420Register as MDMCTRL0;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CC2420Register as RXCTRL1;
  uses interface CC2420Register as RSSI;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SXOSCOFF;
  uses interface CC2420Strobe as SXOSCON;
}

implementation {

  norace uint8_t radio_state = S_STOPPED;
  msg_t *last_pkt = NULL;
  
  void startOscillator();

  norace msg_t* ONE_NOK buffer_msg;

  norace bool m_receiving = FALSE;

  uint16_t checks;
  uint16_t detections;

  /** Byte reception/transmission indicator */
  bool sfdHigh;

  void loadTXFIFO();
  void attemptSend();
  void beginReceive();
  void receive();


  command error_t Mgmt.start() {
    if (radio_state != S_STOPPED) {
      signal Mgmt.startDone(SUCCESS);
      return SUCCESS;
    } 

    dbgs(F_RADIO, S_NONE, DBGS_MGMT_START, 0, 0);

    radio_state = S_STARTING;
    /* First do Init */
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();

    /* Start V Reg */
    call VREN.set();
    call StartupTimer.start( CC2420_TIME_VREN );

    return SUCCESS;
  }

  task void stopDone_task() {
    signal Module.drop_message(buffer_msg);
    signal Mgmt.stopDone( SUCCESS );
  }

  command error_t Mgmt.stop() {
    dbgs(F_RADIO, S_NONE, DBGS_MGMT_STOP, 0, 0);
    if (radio_state != S_STOPPED) {
      radio_state = S_STOPPED;
      call CSN.set();
      call InterruptFIFOP.disable();
      dbg("Radio", "Radio CC2420 Mgmt.stop\n");
      signal Module.drop_message( buffer_msg );

      /* From TX */
      call CaptureSFD.disable();
      call SpiResource.release();  // REMOVE
      call CSN.set();

      call CaptureSFD.disable();
      call CSN.set();
      /* End of TX */

      /* Stop V Reg */
      call RSTN.clr();
      call VREN.clr();
      call RSTN.set();
    }
    post stopDone_task();
    return SUCCESS;
  }

  command error_t RadioCall.send(msg_t *msg) {
    if (radio_state != S_LOADED) return FAIL;
    
    radio_state = S_TRANSMITTING;
    
    if ( call SpiResource.immediateRequest() == SUCCESS )
      atomic attemptSend();
    else
      call SpiResource.request();
    return SUCCESS;
  }

  command error_t RadioCall.resend(msg_t *msg) {
    radio_state = S_LOADED;
    return call RadioCall.resend(msg);
  }

  command uint8_t RadioCall.getMaxSize(msg_t *msg) {
    return SIMPLE_CC2420_MAX_MESSAGE_SIZE;
  }

  command uint8_t* RadioCall.getPayload(msg_t *msg) {
    return (uint8_t*)&msg->data;
  }

  command error_t RadioCall.load(msg_t *msg) {
    if (radio_state != S_STARTED) return FAIL;

    radio_state = S_LOADING;
    last_pkt = msg;
   
    if ( call SpiResource.immediateRequest() == SUCCESS )
      loadTXFIFO();
    else 
      call SpiResource.request();
    return SUCCESS;
  }

  command uint8_t RadioCall.sampleCCA(msg_t *msg) {
    if (radio_state == S_STOPPED) return 0;
    return call CCA.get();
  }

  command uint8_t RadioCall.cancel(msg_t *msg) {
    switch(radio_state) {
      case S_STOPPED:
        return FAIL;

      case S_LOADED:
      case S_LOADING:
      case S_TRANSMITTING:
        radio_state = S_CANCEL;
        last_pkt = NULL;
        if (call SpiResource.immediateRequest() == SUCCESS  ) {
          call CSN.clr();
          call SFLUSHTX.strobe();
          call CSN.set();
          call SpiResource.release();
          radio_state = S_STARTED;
        } else {
          call SpiResource.request();
        }

      default:
        return SUCCESS;
    }
  }

  async event void InterruptFIFOP.fired() {
    if (radio_state != S_STOPPED) beginReceive();
  }

  task void receiveDone_task() {

    /* waitForNextPacket */
    if ( radio_state == S_STOPPED ) {
      call SpiResource.release();
      return;
    }

    /*
     * The FIFOP pin here is high when there are 0 bytes in the RX FIFO
     * and goes low as soon as there are bytes in the RX FIFO.  The pin
     * is inverted from what the datasheet says, and its threshold is 127.
     * Whenever the FIFOP line goes low, as you can see from the interrupt
     * handler elsewhere in this module, it means we drop_message a new packet.
     * If the line stays low without generating an interrupt, that means
     * there's still more data to be drop_message.
     */
    if ((!enable_auto_crc) || (buffer_msg->crc)) {
      signal RadioSignal.receive(buffer_msg, (uint8_t*)&buffer_msg->data, buffer_msg->len);
    } else {
      signal Module.drop_message(buffer_msg);
    }

    buffer_msg = signal Module.next_message();

    if ( ( call FIFO.get() ) || !call FIFOP.get() ) {
      // A new packet is buffered up and ready to go
      beginReceive();
    } else {
      // Wait for the next packet to arrive
      radio_state = S_STARTED;
      call SpiResource.release();
    }
  }


  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len, error_t error ) {
    uint8_t* buf = (uint8_t*) buffer_msg;

    if (radio_state == S_STOPPED) return;

    buffer_msg->len = buf[0];
    buffer_msg->fennec.conf = buf[1];

    switch( radio_state ) {

    case S_RX_LENGTH:
      radio_state = S_RX_FCF;
        //printf("RXFIFO LEN\n");
        call RXFIFO.continueRead(buf + SIMPLE_CC2420_FIRST, SIMPLE_CC2420_MIN_MESSAGE_SIZE);
        break;

    case S_RX_FCF:
      radio_state = S_RX_PAYLOAD;
      if ((buffer_msg->len >= SIMPLE_CC2420_MIN_MESSAGE_SIZE) &&
        (buffer_msg->len < SIMPLE_CC2420_MAX_MESSAGE_SIZE+1) &&
        (signal RadioSignal.check_destination(buffer_msg, (uint8_t*)&buffer_msg->data) == TRUE)) {
        call RXFIFO.continueRead(buf + SIMPLE_CC2420_FIRST + SIMPLE_CC2420_MIN_MESSAGE_SIZE,
                               buffer_msg->len - SIMPLE_CC2420_MIN_MESSAGE_SIZE);
        //printf("RXFIFO pass FCF\n");
      } else {
        //printf("RXFIFO fail FCF len %d check %d\n", buffer_msg->len, signal RadioSignal.check_destination(buffer_msg, (uint8_t*)&buffer_msg->data));
        call CSN.set();
        call CSN.clr();
        call SFLUSHRX.strobe();
        call SFLUSHRX.strobe();
        call CSN.set();
        call SpiResource.release();
        radio_state = S_STARTED;
      }
      //printfflush();
      break;

    case S_RX_PAYLOAD:
      //printf("RXFIFO PAYLOAD\n");
      call CSN.set();
      call SpiResource.release();
      buffer_msg->crc = buf[ buffer_msg->len ] >> 7;
      buffer_msg->lqi = buf[ buffer_msg->len ] & 0x7f;
      buffer_msg->rssi = buf[ buffer_msg->len - 1];

      post receiveDone_task();
      return;

    default:
      call CSN.set();
      call SpiResource.release();
      break;

    }
  }

  void beginReceive() {
    radio_state = S_RX_LENGTH;
    if(call SpiResource.isOwner()) {
      receive();

    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();

    } else {
      call SpiResource.request();
    }
  }


  /**
   * The first byte of each packet is the length byte.  Read in that single
   * byte, and then read in the rest of the packet.  The CC2420 could contain
   * multiple packets that have been buffered up, so if something goes wrong,
   * we necessarily want to flush out the FIFO unless we have to.
   */
  void receive() {
    call CSN.clr();
    call RXFIFO.beginRead( (uint8_t*)buffer_msg, SIMPLE_CC2420_FIRST );
  }

  task void sendDone_task() {
    if (last_pkt != NULL) {
      signal RadioSignal.sendDone( last_pkt, SUCCESS );
      radio_state = S_STARTED;
    }
  }

  async event void CaptureSFD.captured( uint16_t time ) {
    if (radio_state == S_STOPPED) return;

    atomic {
      switch( radio_state ) {
        
        case S_SFD:
          radio_state = S_EFD;
          sfdHigh = TRUE;
          m_receiving = FALSE;
          call CaptureSFD.captureFallingEdge();
          call SpiResource.release();
          if ( call SFD.get() ) {
            break;
          }

        case S_EFD:
          sfdHigh = FALSE;
          call CaptureSFD.captureRisingEdge();  
          post sendDone_task();
          if ( !call SFD.get() ) {
            break;
          }
        
        default:
          if ( !m_receiving && sfdHigh == FALSE ) {
            sfdHigh = TRUE;
            call CaptureSFD.captureFallingEdge();
            m_receiving = TRUE;
            if ( call SFD.get() ) {
              return;
            }
          }
        
          if ( sfdHigh == TRUE ) {
            sfdHigh = FALSE;
            call CaptureSFD.captureRisingEdge();
            m_receiving = FALSE;
            break;
          }
      }
    }
  }

 
  event void SpiResource.granted() {
    switch( radio_state ) {
      case S_LOADING:
        loadTXFIFO();
        break;
      
      case S_TRANSMITTING:
        attemptSend();
        break;

      case S_STARTING:
        call CSN.clr();
        startOscillator();
        break;

      case S_CANCEL:
        call CSN.clr();
        call SFLUSHTX.strobe();
        call CSN.set();
        call SpiResource.release();
        radio_state = S_STARTED;

    default:
      if (radio_state == S_STOPPED) {
        call SpiResource.release();
      } else {
        receive();
      }
      break;
    }
  }

  task void loadDone_task() {
    if (last_pkt != NULL) {
      radio_state = S_LOADED;
      signal RadioSignal.loadDone( last_pkt, SUCCESS );
    }
  }
  
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
    if (radio_state == S_STOPPED) return;
    call CSN.set();
    call SpiResource.release();
    post loadDone_task();
  }

  void attemptSend() {
    atomic {
      call CSN.clr();
      call STXON.strobe();
      call SNOP.strobe();
      radio_state = S_SFD;
      call CSN.set();
    }
  }
  
  void loadTXFIFO() {
    call CSN.clr();
 
    if (enable_auto_crc) {
      call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
			 ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
                         ( (tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );

    } else {
      call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
                         ( (tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
    }
    
    call TXFIFO.write(TCAST(uint8_t * COUNT(last_pkt->len), last_pkt), last_pkt->len);
  }
  

  void startOscillator() {
    atomic {
      call IOCFG1.write( CC2420_SFDMUX_XOSC16M_STABLE <<
                         CC2420_IOCFG1_CCAMUX );

      call InterruptCCA.enableRisingEdge();
      call SXOSCON.strobe();

      call IOCFG0.write( ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
          ( 127 << CC2420_IOCFG0_FIFOP_THR ) );

      call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
          ( ( (radio_channel - 11)*5+357 ) << CC2420_FSCTRL_FREQ ) );

      /**
       * Write the MDMCTRL0 register
       * Disabling hardware address recognition improves acknowledgment success
       * rate and low power communications reliability by causing the local node
       * to do work while the real destination node of the packet is acknowledging.
       */
      call MDMCTRL0.write( ( 1 << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
          ( 0 << CC2420_MDMCTRL0_ADR_DECODE ) |
          ( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
          ( 3 << CC2420_MDMCTRL0_CCA_MOD ) |
          ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
          ( 0 << CC2420_MDMCTRL0_AUTOACK ) |
          ( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );

      // Jon Green:
      // MDMCTRL1.CORR_THR is defaulted to 20 instead of 0 like the datasheet says
      // If we add in changes to MDMCTRL1, be sure to include this fix.

      call RXCTRL1.write( ( 1 << CC2420_RXCTRL1_RXBPF_LOCUR ) |
          ( 1 << CC2420_RXCTRL1_LOW_LOWGAIN ) |
          ( 1 << CC2420_RXCTRL1_HIGH_HGM ) |
          ( 1 << CC2420_RXCTRL1_LNA_CAP_ARRAY ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_TAIL ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_VCM ) |
          ( 2 << CC2420_RXCTRL1_RXMIX_CURRENT ) );
    }
  }

  async event void StartupTimer.fired() {
    call RSTN.clr();
    call RSTN.set();
    call SpiResource.request();
  }

  task void startDone_task() {
    buffer_msg = signal Module.next_message();
    call InterruptFIFOP.enableFallingEdge();

    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
    call CaptureSFD.captureRisingEdge();

    m_receiving = FALSE;

    /* RX ON */
    call SRXON.strobe();

    /* call Resource.release(); */
    call CSN.set();
    call SpiResource.release();

    radio_state = S_STARTED;
    signal Mgmt.startDone( SUCCESS );
  }

  async event void InterruptCCA.fired() {
    call InterruptCCA.disable();
    call IOCFG1.write( 0 );
    call CSN.set();
    call CSN.clr();
    post startDone_task();
  }

  async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t er ) {}
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}
}

