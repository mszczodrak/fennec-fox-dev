module cc2420DriverP @safe() {

  provides interface Init;
  provides interface ReceiveIndicator as EnergyIndicator;
  
  uses interface GpioCapture as CaptureSFD;
  uses interface GeneralIO as CCA;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as SFD;

  uses interface Resource as SpiResource;
  uses interface ChipSpiResource;
  uses interface CC2420Fifo as TXFIFO;
  uses interface CC2420Ram as TXFIFO_RAM;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SNOP;
  uses interface CC2420Strobe as STXON;
  uses interface CC2420Strobe as STXONCCA;
  uses interface CC2420Strobe as SFLUSHTX;
  uses interface CC2420Register as MDMCTRL1;

  uses interface CC2420Strobe as STXENC;
  uses interface CC2420Register as SECCTRL0;
  uses interface CC2420Register as SECCTRL1;
  uses interface CC2420Ram as KEY0;
  uses interface CC2420Ram as KEY1;
  uses interface CC2420Ram as TXNONCE;

  uses interface cc2420RadioParams;

}

implementation {

  norace message_t * ONE_NOK m_msg;
  
  void low_level_init() {
    call CCA.makeInput();
    call CSN.makeOutput();
    call SFD.makeInput();
  }

/*
  void low_level_start() {
    call CaptureSFD.captureRisingEdge();
    atomic abortSpiRelease = FALSE;
  }

  void low_level_stop() {
    call CaptureSFD.disable();
    call SpiResource.release();  // REMOVE
    call CSN.set();
  }

  void low_level_load(message_t* msg) {
    if ( acquireSpiResource() == SUCCESS ) {
      loadTXFIFO();
    }
  }

  void low_level_send(message_t* msg) {
    if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
  }

  void low_level_something_wrong() {
    call SFLUSHTX.strobe();
    call CaptureSFD.captureRisingEdge();
    releaseSpiResource();
  }
*/ 


  /* -------------------------- */

  cc2420_header_t* ONE getHeader( message_t* ONE msg ) {
    return TCAST(cc2420_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( cc2420_header_t ));
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }


  /***************** Init Commands *****************/
  command error_t Init.init() {
    low_level_init();
    return SUCCESS;
  }

  command bool EnergyIndicator.isReceiving() {
    return !(call CCA.get());
  }
  
/*
  command bool ByteIndicator.isReceiving() {
    bool high;
    atomic high = sfdHigh;
    return high;
  }
*/
  

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
/*
    uint8_t cur_state;

    atomic {
      cur_state = m_state;
    }

    switch( cur_state ) {
    case S_LOAD:
      loadTXFIFO();
      break;
      
    case S_BEGIN_TRANSMIT:
      attemptSend();
      break;
      
    case S_CANCEL:
      call CSN.clr();
      call SFLUSHTX.strobe();
      call CSN.set();
      releaseSpiResource();
      atomic {
        m_state = S_STARTED;
      }
      signal RadioTransmit.sendDone( m_msg, ECANCEL );
      break;
      
    default:
      releaseSpiResource();
      break;
    }
*/
  }

  void low_level_cancel() {
/*
    call CSN.clr();
    call SFLUSHTX.strobe();
    call CSN.set();
    releaseSpiResource();
*/
  }

  async event void CaptureSFD.captured( uint16_t time ) {
  }


  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
//    if(abortSpiRelease) {
//      call ChipSpiResource.abortRelease();
//    }
  }



  /***************** TXFIFO Events ****************/
  /**
   * The TXFIFO is used to load packets into the transmit buffer on the
   * chip
   */
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
                                     error_t error ) {

/*
    call CSN.set();
    load_done(m_msg, error);
*/
  }

  
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }
  
  event void cc2420RadioParams.receive_status(uint16_t status_flag) {
  }


}

