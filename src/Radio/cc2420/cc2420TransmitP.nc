#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"

module cc2420TransmitP @safe() {

  provides interface StdControl;
  provides interface RadioTransmit;
  provides interface RadioBackoff;
  provides interface ReceiveIndicator as ByteIndicator;
  
  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface Alarm<T32khz,uint32_t> as RadioTimer;

  uses interface GpioCapture as CaptureSFD;
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

  uses interface CC2420Receive;
  uses interface Leds;

  uses interface cc2420RadioParams;

  provides interface Receive;
  uses interface Receive as SubReceive;
  uses interface ReceiveIndicator as EnergyIndicator;

  uses interface StdControl as RadioStdControl;
}

implementation {

  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_LOAD,
    S_SAMPLE_CCA,
    S_BEGIN_TRANSMIT,
    S_SFD,
    S_EFD,
    S_ACK_WAIT,
    S_CANCEL,
  } cc2420_transmit_state_t;


  norace message_t * ONE_NOK m_msg;
  norace bool m_cca;
  norace cc2420_transmit_state_t m_state = S_STOPPED;

  
  
  
  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  

  /***************** Prototypes ****************/
  void loadTXFIFO();
  void attemptSend();
  void congestionBackoff();
  error_t releaseSpiResource();
  void signalDone( error_t err );


  void low_level_start();
  void low_level_stop();
  error_t low_level_load(message_t* msg);
  error_t low_level_send(message_t* msg, bool useCca);
  void low_level_cancel();

  void low_level_send_done( error_t err) {
    atomic m_state = S_STARTED;
    signal RadioTransmit.sendDone( m_msg, err );
  }
 
  /* -------------------------- */

  cc2420_header_t* ONE getHeader( message_t* ONE msg ) {
    return TCAST(cc2420_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( cc2420_header_t ));
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    low_level_start();
    atomic {
      m_state = S_STARTED;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call RadioStdControl.stop();
    low_level_stop();
    atomic {
      m_state = S_STOPPED;
      call BackoffTimer.stop();
    }
    return SUCCESS;
  }


  /***************** Functions ****************/
  /**
   * Set up a message to be sent. First load it into the outbound tx buffer
   * on the chip, then attempt to send it.
   * @param *p_msg Pointer to the message that needs to be sent
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  async command error_t RadioTransmit.send( message_t* ONE p_msg, bool useCca ) {
    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }

      if ( m_state != S_STARTED ) {
        return FAIL;
      }

      m_state = S_LOAD;
      m_cca = useCca;
      m_msg = p_msg;
      totalCcaChecks = 0;
    }

    low_level_load(p_msg);

    return SUCCESS;
  }

  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  async command error_t RadioTransmit.resend(bool useCca) {
    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }

      if ( m_state != S_STARTED ) {
        return FAIL;
      }

      m_cca = useCca;
      m_state = useCca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
      totalCcaChecks = 0;
    }

    if(m_cca) {
      signal RadioBackoff.requestInitialBackoff(m_msg);
      if (myInitialBackoff) {
        call BackoffTimer.start( myInitialBackoff );
      } else {
        signal BackoffTimer.fired();
      }
    } else {
      low_level_send(m_msg, useCca);
    }

    return SUCCESS;
  }

  async command error_t RadioTransmit.cancel() {
    atomic {
      switch( m_state ) {
      case S_LOAD:
      case S_SAMPLE_CCA:
      case S_BEGIN_TRANSMIT:
        m_state = S_CANCEL;
        break;
        
      default:
        // cancel not allowed while radio is busy transmitting
        return FAIL;
      }
    }

    return SUCCESS;
  }

  

  /***************** RadioBackoff Commands ****************/
  /**
   * Must be called within a requestInitialBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setInitialBackoff(uint16_t backoffTime) {
    myInitialBackoff = backoffTime;
  }
  
  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setCongestionBackoff(uint16_t backoffTime) {
    myCongestionBackoff = backoffTime;
  }
  
  async command void RadioBackoff.setCca(bool useCca) {
  }
  

  event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
//    dbg("Mac", "Mac: CSMA/CA receive\n");
    return signal Receive.receive(msg, payload, len);
  }

  void low_level_cancel_done() {
      atomic {
        m_state = S_STARTED;
      }
      signal RadioTransmit.sendDone( m_msg, ECANCEL );
  }


  void load_done(message_t* msg, error_t error) {
    if ( m_state == S_CANCEL ) {
      atomic {
        low_level_cancel();
      }
      m_state = S_STARTED;
      signal RadioTransmit.sendDone( msg, ECANCEL );

    } else if ( !m_cca ) {
      atomic {
        m_state = S_BEGIN_TRANSMIT;
      }
      low_level_send(m_msg, m_cca);
    } else {
      atomic {
        m_state = S_SAMPLE_CCA;
      }

      signal RadioBackoff.requestInitialBackoff(msg);
      if (myInitialBackoff) {
        call BackoffTimer.start(myInitialBackoff);
      } else {
        signal BackoffTimer.fired();
      }
    }
  }


  /***************** Timer Events ****************/
  /**
   * The backoff timer is mainly used to wait for a moment before trying
   * to send a packet again. But we also use it to timeout the wait for
   * an acknowledgement, and timeout the wait for an SFD interrupt when
   * we should have gotten one.
   */
  async event void BackoffTimer.fired() {
    atomic {
      switch( m_state ) {
        
      case S_SAMPLE_CCA : 
        // sample CCA and wait a little longer if free, just in case we
        // sampled during the ack turn-around window
        if ( !call EnergyIndicator.isReceiving() ) {
          m_state = S_BEGIN_TRANSMIT;
          call BackoffTimer.start( CC2420_TIME_ACK_TURNAROUND );
          
        } else {
          congestionBackoff();
        }
        break;
        
      case S_BEGIN_TRANSMIT:
        low_level_send(m_msg, m_cca);
        break;

      case S_CANCEL:
        low_level_cancel();
        m_state = S_STARTED;
        signal RadioTransmit.sendDone( m_msg, ECANCEL );
        break;
        
      default:
        break;
      }
    }
  }
      
  /**  
   * Congestion Backoff
   */
  void congestionBackoff() {
    atomic {
      signal RadioBackoff.requestCongestionBackoff(m_msg);
      if (myCongestionBackoff) {
        call BackoffTimer.start(myCongestionBackoff);
      } else {
        signal BackoffTimer.fired();
      }
    }
  }
  
  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
  }


  event void cc2420RadioParams.receive_status(uint16_t status_flag) {
  }


  void send_done(error_t error) {
    if (error == EBUSY) {
      m_state = S_SAMPLE_CCA;
      totalCcaChecks = 0;
      congestionBackoff();
    }

  }
























  /* low level */

  norace message_t * ONE_NOK radio_msg;
  norace bool radio_cca;

  norace cc2420_transmit_state_t radio_state = S_STOPPED;

  /** Byte reception/transmission indicator */
  bool sfdHigh;

  bool m_receiving = FALSE;

  norace uint8_t m_tx_power;
  uint16_t m_prev_time;

  /** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
  bool abortSpiRelease;

  // This specifies how many jiffies the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2420_ABORT_PERIOD = 320
  };


  void PacketTimeStampclear(message_t* msg)
  {
    (getMetadata( msg ))->timesync = FALSE;
    (getMetadata( msg ))->timestamp = CC2420_INVALID_TIMESTAMP;
  }

  void PacketTimeStampset(message_t* msg, uint32_t value)
  {
    (getMetadata( msg ))->timestamp = value;
  }

  bool PacketTimeSyncOffsetisSet(message_t* msg)
  {
    return ((getMetadata( msg ))->timesync);
  }



  //returns offset of timestamp from the beginning of cc2420 header which is
  //          sizeof(cc2420_header_t)+datalen-sizeof(timesync_radio_t)
  //uses packet length of the message which is
  //          MAC_HEADER_SIZE+MAC_FOOTER_SIZE+datalen
  uint8_t PacketTimeSyncOffsetget(message_t* msg)
  {
    return (getHeader(msg))->length
            + (sizeof(cc2420_header_t) - MAC_HEADER_SIZE)
            - MAC_FOOTER_SIZE
            - sizeof(timesync_radio_t);
  }


  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
    if(abortSpiRelease) {
      call ChipSpiResource.abortRelease();
    }
  }
 


 

  void signalDone( error_t err ) {
    atomic radio_state = S_STARTED;
    abortSpiRelease = FALSE;
    call ChipSpiResource.attemptRelease();
    low_level_send_done(err);
  }



  // this method converts a 16-bit timestamp into a 32-bit one
  inline uint32_t getTime32(uint16_t captured_time)
  {
    uint32_t now = call BackoffTimer.getNow();

    // the captured_time is always in the past
    return now - (uint16_t)(now - captured_time);
  }



  /**
   * Attempt to send the packet we have loaded into the tx buffer on
   * the radio chip.  The STXONCCA will send the packet immediately if
   * the channel is clear.  If we're not concerned about whether or not
   * the channel is clear (i.e. radio_cca == FALSE), then STXON will send the
   * packet without checking for a clear channel.
   *
   * If the packet didn't get sent, then congestion == TRUE.  In that case,
   * we reset the backoff timer and try again in a moment.
   *
   * If the packet got sent, we should expect an SFD interrupt to take
   * over, signifying the packet is getting sent.
   *
   * If security is enabled, STXONCCA or STXON will perform inline security
   * options before transmitting the packet.
   */
  void attemptSend() {
    uint8_t status;
    bool congestion = TRUE;

    atomic {
      call CSN.clr();
      status = radio_cca ? call STXONCCA.strobe() : call STXON.strobe();
      if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
        status = call SNOP.strobe();
        if ( status & CC2420_STATUS_TX_ACTIVE ) {
          congestion = FALSE;
        }
      }

      call CSN.set();
    }

    if ( congestion ) {
      send_done(EBUSY);
      releaseSpiResource();
    } else {
      radio_state = S_SFD;
      call RadioTimer.start(CC2420_ABORT_PERIOD);
    }
  }







  command bool ByteIndicator.isReceiving() {
    bool high;
    atomic high = sfdHigh;
    return high;
  }



  async event void CC2420Receive.receive( uint8_t type, message_t* ack_msg ) {
    cc2420_header_t* ack_header;
    cc2420_header_t* msg_header;
    cc2420_metadata_t* msg_metadata;
    uint8_t* ack_buf;
    uint8_t length;

    if ( type == IEEE154_TYPE_ACK && radio_msg) {
      ack_header = getHeader( ack_msg );
      msg_header = getHeader( radio_msg );

      if ( radio_state == S_ACK_WAIT && msg_header->dsn == ack_header->dsn ) {
        call RadioTimer.stop();

        msg_metadata = getMetadata( radio_msg );
        ack_buf = (uint8_t *) ack_header;
        length = ack_header->length;

        msg_metadata->ack = TRUE;
        msg_metadata->rssi = ack_buf[ length - 1 ];
        msg_metadata->lqi = ack_buf[ length ] & 0x7f;
        signalDone(SUCCESS);
      }
    }
  }

  void low_level_something_wrong() {
    call SFLUSHTX.strobe();
    call CaptureSFD.captureRisingEdge();
    releaseSpiResource();
  }



  async event void RadioTimer.fired() {
    atomic {
      switch( radio_state ) {

      case S_ACK_WAIT:
        signalDone( SUCCESS );
        break;

      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        low_level_something_wrong();
        signalDone( ERETRY );
        break;

      default:
        break;
      }
    }

  }



  /**
   * The CaptureSFD event is actually an interrupt from the capture pin
   * which is connected to timing circuitry and timer modules.  This
   * type of interrupt allows us to see what time (being some relative value)
   * the event occurred, and lets us accurately timestamp our packets.  This
   * allows higher levels in our system to synchronize with other nodes.
   *
   * Because the SFD events can occur so quickly, and the interrupts go
   * in both directions, we set up the interrupt but check the SFD pin to
   * determine if that interrupt condition has already been met - meaning,
   * we should fall through and continue executing code where that interrupt
   * would have picked up and executed had our microcontroller been fast enough.
   */
  async event void CaptureSFD.captured( uint16_t time ) {
    uint32_t time32;
    uint8_t sfd_state = 0;
    atomic {
      time32 = getTime32(time);
      switch( radio_state ) {

      case S_SFD:
        radio_state = S_EFD;
        sfdHigh = TRUE;
        // in case we got stuck in the receive SFD interrupts, we can reset
        // the state here since we know that we are not receiving anymore
        m_receiving = FALSE;
        call CaptureSFD.captureFallingEdge();
        PacketTimeStampset(radio_msg, time32);
        if (PacketTimeSyncOffsetisSet(radio_msg)) {
           uint8_t absOffset = sizeof(message_header_t)-sizeof(cc2420_header_t)+ PacketTimeSyncOffsetget(radio_msg);
           timesync_radio_t *timesync = (timesync_radio_t *)((nx_uint8_t*)radio_msg+absOffset);
           // set timesync event time as the offset between the event time and the SFD interrupt time (TEP  133)
           *timesync  -= time32;
           call CSN.clr();
           call TXFIFO_RAM.write( absOffset, (uint8_t*)timesync, sizeof(timesync_radio_t) );
           call CSN.set();
           //restoring the event time to the original value
           *timesync  += time32;
        }

        if ( (getHeader( radio_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          // This is an ack packet, don't release the chip's SPI bus lock.
          abortSpiRelease = TRUE;
        }
        releaseSpiResource();
        call RadioTimer.stop();

        if ( call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */

      case S_EFD:
        sfdHigh = FALSE;
        call CaptureSFD.captureRisingEdge();

        if ( (getHeader( radio_msg ))->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
          radio_state = S_ACK_WAIT;
          call RadioTimer.start( CC2420_ACK_WAIT_DELAY );
        } else {
          signalDone(SUCCESS);
        }

        if ( !call SFD.get() ) {
          break;
        }
        /** Fall Through because the next interrupt was already received */

      default:
        /* this is the SFD for received messages */
        if ( !m_receiving && sfdHigh == FALSE ) {
          sfdHigh = TRUE;
          call CaptureSFD.captureFallingEdge();
          // safe the SFD pin status for later use
          sfd_state = call SFD.get();
          call CC2420Receive.sfd( time32 );
          m_receiving = TRUE;
          m_prev_time = time;
          if ( call SFD.get() ) {
            // wait for the next interrupt before moving on
            return;
          }
          // if SFD.get() = 0, then an other interrupt happened since we
          // reconfigured CaptureSFD! Fall through
        }

        if ( sfdHigh == TRUE ) {
          sfdHigh = FALSE;
          call CaptureSFD.captureRisingEdge();
          m_receiving = FALSE;
          /* if sfd_state is 1, then we fell through, but at the time of
           * saving the time stamp the SFD was still high. Thus, the timestamp
           * is valid.
           * if the sfd_state is 0, then either we fell through and SFD
           * was low while we safed the time stamp, or we didn't fall through.
           * Thus, we check for the time between the two interrupts.
           * FIXME: Why 10 tics? Seams like some magic number...
           */
          if ((sfd_state == 0) && (time - m_prev_time < 10) ) {
            call CC2420Receive.sfd_dropped();
            if (radio_msg)
              PacketTimeStampclear(radio_msg);
          }
          break;
        }
      }
    }
  }











  /**
   * Setup the packet transmission power and load the tx fifo buffer on
   * the chip with our outbound packet.
   *
   * Warning: the tx_power metadata might not be initialized and
   * could be a value other than 0 on boot.  Verification is needed here
   * to make sure the value won't overstep its bounds in the TXCTRL register
   * and is transmitting at max power by default.
   *
   * It should be possible to manually calculate the packet's CRC here and
   * tack it onto the end of the header + payload when loading into the TXFIFO,
   * so the continuous modulation low power listening strategy will continually
   * deliver valid packets.  This would increase receive reliability for
   * mobile nodes and lossy connections.  The crcByte() function should use
   * the same CRC polynomial as the CC2420's AUTOCRC functionality.
   */
  void loadTXFIFO() {
    cc2420_header_t* header = getHeader( radio_msg );
    uint8_t tx_power = (getMetadata( radio_msg ))->tx_power;

    if ( !tx_power ) {
      tx_power = call cc2420RadioParams.get_power();
    }

    call CSN.clr();

    if ( m_tx_power != tx_power ) {
      call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
                         ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
                         ( 1 << CC2420_TXCTRL_RESERVED ) |
                         ( (tx_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
    }

    m_tx_power = tx_power;

    {
      uint8_t tmpLen __DEPUTY_UNUSED__ = header->length - 1;
      call TXFIFO.write(TCAST(uint8_t * COUNT(tmpLen), header), header->length - 1);
    }
  }




  void low_level_start() {
    radio_state = S_STARTED;
    m_tx_power = 0;
    m_receiving = FALSE;
    call CaptureSFD.captureRisingEdge();
    atomic abortSpiRelease = FALSE;
  }

  void low_level_stop() {
    radio_state = S_STOPPED;
    call RadioTimer.stop();
  }


  error_t low_level_load(message_t* msg) {
    radio_msg = msg;
    radio_state = S_LOAD;
    if ( acquireSpiResource() == SUCCESS ) {
      loadTXFIFO();
    }
    return SUCCESS;
  }

  error_t low_level_send(message_t* msg, bool useCca) {
    if (msg != radio_msg)
      return FAIL;

    radio_cca = useCca;
    radio_state = S_BEGIN_TRANSMIT;

    if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
    return SUCCESS;
  }


  void low_level_cancel() {
    call CSN.clr();
    call SFLUSHTX.strobe();
    call CSN.set();
    releaseSpiResource();
    radio_state = S_STARTED;
  }



  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    uint8_t cur_state;

    atomic {
      cur_state = radio_state;
    }

    switch( cur_state ) {
    case S_LOAD:
      loadTXFIFO();
      break;

    case S_BEGIN_TRANSMIT:
      attemptSend();
      break;

    case S_CANCEL:
      low_level_cancel();
      low_level_cancel_done();
      break;

    default:
      releaseSpiResource();
      break;
    }
  }




  /***************** TXFIFO Events ****************/
  /**
   * The TXFIFO is used to load packets into the transmit buffer on the
   * chip
   */
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
    call CSN.set();
    releaseSpiResource();
    load_done(radio_msg, error);
  }


  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }




}

