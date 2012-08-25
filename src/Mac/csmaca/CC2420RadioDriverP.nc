#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"

module CC2420RadioDriverP @safe() {

  provides interface StdControl;
  provides interface CC2420Transmit as Send;
  provides interface RadioBackoff;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;
  
  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface CC2420Packet;
  uses interface CC2420PacketBody;
  uses interface PacketTimeStamp<T32khz,uint32_t>;
  uses interface PacketTimeSyncOffset;
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

  uses interface CC2420Receive;
  uses interface Leds;

  uses interface ParametersCC2420;
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

  // This specifies how many jiffies the stack should wait after a
  // TXACTIVE to receive an SFD interrupt before assuming something is
  // wrong and aborting the send. There seems to be a condition
  // on the micaZ where the SFD interrupt is never handled.
  enum {
    CC2420_ABORT_PERIOD = 320
  };

  
  norace message_t * ONE_NOK m_msg;
  
  norace bool m_cca;
  
  norace uint8_t m_tx_power;
  norace uint8_t default_tx_power;
  
  cc2420_transmit_state_t m_state = S_STOPPED;

  bool m_receiving = FALSE;
  
  uint16_t m_prev_time;
  
  /** Byte reception/transmission indicator */
  bool sfdHigh;
  
  /** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
  bool abortSpiRelease;
  
  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  

  /***************** Prototypes ****************/
  error_t send( message_t * ONE p_msg, bool cca );
  error_t resend( bool cca );
  void loadTXFIFO();
  void attemptSend();
  void congestionBackoff();
  error_t acquireSpiResource();
  error_t releaseSpiResource();
  void signalDone( error_t err );
  
  
  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    atomic {
      call CaptureSFD.captureRisingEdge();
      m_state = S_STARTED;
      m_receiving = FALSE;
      abortSpiRelease = FALSE;
      m_tx_power = 0;
      default_tx_power = call ParametersCC2420.get_power();
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      call BackoffTimer.stop();
      call CaptureSFD.disable();
      call SpiResource.release();  // REMOVE
      call CSN.set();
    }
    return SUCCESS;
  }


  /**************** Send Commands ****************/
  async command error_t Send.send( message_t* ONE p_msg, bool useCca ) {
    return send( p_msg, useCca );
  }

  async command error_t Send.resend(bool useCca) {
    return resend( useCca );
  }

  async command error_t Send.cancel() {
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

  async command error_t Send.modify( uint8_t offset, uint8_t* buf, 
                                     uint8_t len ) {
    call CSN.clr();
    call TXFIFO_RAM.write( offset, buf, len );
    call CSN.set();
    return SUCCESS;
  }
  
  /***************** Indicator Commands ****************/
  command bool EnergyIndicator.isReceiving() {
    return !(call CCA.get());
  }
  
  command bool ByteIndicator.isReceiving() {
    bool high;
    atomic high = sfdHigh;
    return high;
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
  
  // this method converts a 16-bit timestamp into a 32-bit one
  inline uint32_t getTime32(uint16_t captured_time)
  {
    uint32_t now = call BackoffTimer.getNow();

    // the captured_time is always in the past
    return now - (uint16_t)(now - captured_time);
  }

  /***************** ChipSpiResource Events ****************/
  async event void ChipSpiResource.releasing() {
    if(abortSpiRelease) {
      call ChipSpiResource.abortRelease();
    }
  }
  
  
  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
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
      signal Send.sendDone( m_msg, ECANCEL );
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
  async event void TXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len,
                                     error_t error ) {

    call CSN.set();
    if ( m_state == S_CANCEL ) {
      atomic {
        call CSN.clr();
        call SFLUSHTX.strobe();
        call CSN.set();
      }
      releaseSpiResource();
      m_state = S_STARTED;
      signal Send.sendDone( m_msg, ECANCEL );
      
    } else if ( !m_cca ) {
      atomic {
        m_state = S_BEGIN_TRANSMIT;
      }
      attemptSend();
      
    } else {
      releaseSpiResource();
      atomic {
        m_state = S_SAMPLE_CCA;
      }
      
      signal RadioBackoff.requestInitialBackoff(m_msg);
      if (myInitialBackoff) {
        call BackoffTimer.start(myInitialBackoff);
      } else {
        signal BackoffTimer.fired();
      }
    }
  }

  
  async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, 
      error_t error ) {
  }
  
  
  /***************** Timer Events ****************/
  /**
   * The backoff timer is mainly used to wait for a moment before trying
   * to send a packet again. But we also use it to timeout the wait for
   * an acknowledgement, and timeout the wait for an SFD interrupt when
   * we should have gotten one.
   */
/*
  async event void BackoffTimer.fired() {
    atomic {
      switch( m_state ) {
        
      case S_SAMPLE_CCA : 
        // sample CCA and wait a little longer if free, just in case we
        // sampled during the ack turn-around window
        if ( call CCA.get() ) {
          m_state = S_BEGIN_TRANSMIT;
          call BackoffTimer.start( CC2420_TIME_ACK_TURNAROUND );
          
        } else {
          congestionBackoff();
        }
        break;
        
      case S_BEGIN_TRANSMIT:
      case S_CANCEL:
        if ( acquireSpiResource() == SUCCESS ) {
          attemptSend();
        }
        break;
        
      case S_ACK_WAIT:
        signalDone( SUCCESS );
        break;

      case S_SFD:
        // We didn't receive an SFD interrupt within CC2420_ABORT_PERIOD
        // jiffies. Assume something is wrong.
        call SFLUSHTX.strobe();
        call CaptureSFD.captureRisingEdge();
        releaseSpiResource();
        signalDone( ERETRY );
        break;

      default:
        break;
      }
    }
  }
*/  

    
  /***************** Functions ****************/
  /**
   * Set up a message to be sent. First load it into the outbound tx buffer
   * on the chip, then attempt to send it.
   * @param *p_msg Pointer to the message that needs to be sent
   * @param cca TRUE if this transmit should use clear channel assessment
   */
/*
  error_t send( message_t* ONE p_msg, bool cca ) {
    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_state = S_LOAD;
      m_cca = cca;
      m_msg = p_msg;
      totalCcaChecks = 0;
    }
    
    if ( acquireSpiResource() == SUCCESS ) {
      loadTXFIFO();
    }

    return SUCCESS;
  }
*/  
  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
/*
  error_t resend( bool cca ) {

    atomic {
      if (m_state == S_CANCEL) {
        return ECANCEL;
      }
      
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      
      m_cca = cca;
      m_state = cca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
      totalCcaChecks = 0;
    }
    
    if(m_cca) {
      signal RadioBackoff.requestInitialBackoff(m_msg);
      if (myInitialBackoff) {
        call BackoffTimer.start( myInitialBackoff );
      } else {
        signal BackoffTimer.fired();
      }
    } else if ( acquireSpiResource() == SUCCESS ) {
      attemptSend();
    }
    
    return SUCCESS;
  }
*/

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
  
  error_t acquireSpiResource() {
    error_t error = call SpiResource.immediateRequest();
    if ( error != SUCCESS ) {
      call SpiResource.request();
    }
    return error;
  }

  error_t releaseSpiResource() {
    call SpiResource.release();
    return SUCCESS;
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
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_msg );
    uint8_t tx_power = (call CC2420PacketBody.getMetadata( m_msg ))->tx_power;

    if ( !tx_power ) {
      tx_power = default_tx_power;
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
  
  void signalDone( error_t err ) {
    atomic m_state = S_STARTED;
    abortSpiRelease = FALSE;
    call ChipSpiResource.attemptRelease();
    signal Send.sendDone( m_msg, err );
  }

}

