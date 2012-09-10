#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"
#include "Fennec.h"

module macTransmitP @safe() {

  provides interface StdControl;
  provides interface MacTransmit;

  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface StdControl as RadioControl;

  uses interface csmacaMacParams;
  uses interface Random;

}

implementation {

  norace message_t * ONE_NOK m_msg;
  norace bool m_cca;
  norace uint8_t m_state = S_STOPPED;
  norace uint16_t csmaca_backoff_period;
  norace uint16_t csmaca_min_backoff;
  norace uint16_t csmaca_delay_after_receive;


  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;
  
  void requestInitialBackoff(message_t *msg) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    if ((csmaca_delay_after_receive > 0) && (metadata->rxInterval > 0)) {
      myInitialBackoff = ( call Random.rand16() % (0x4 * csmaca_backoff_period) + csmaca_min_backoff);
    } else {
      myInitialBackoff = ( call Random.rand16() % (0x1F * csmaca_backoff_period) + csmaca_min_backoff);
    }
  }

  void congestionBackoff(message_t *msg) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    if ((csmaca_delay_after_receive > 0) && (metadata->rxInterval > 0)) {
      myCongestionBackoff = ( call Random.rand16() % (0x3 * csmaca_backoff_period) + csmaca_min_backoff);
    } else {
      myCongestionBackoff = ( call Random.rand16() % (0x7 * csmaca_backoff_period) + csmaca_min_backoff);
    }

    if (myCongestionBackoff) {
      call BackoffTimer.start(myCongestionBackoff);
    } else {
      signal BackoffTimer.fired();
    }
  }


  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    csmaca_backoff_period = call csmacaMacParams.get_backoff();
    csmaca_min_backoff = call csmacaMacParams.get_min_backoff();
    csmaca_delay_after_receive = call csmacaMacParams.get_delay_after_receive();

    call RadioControl.start();
    m_state = S_STARTED;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call RadioControl.stop();
    m_state = S_STOPPED;
    call BackoffTimer.stop();
    return SUCCESS;
  }

  /***************** Functions ****************/
  /**
   * Set up a message to be sent. First load it into the outbound tx buffer
   * on the chip, then attempt to send it.
   * @param *p_msg Pointer to the message that needs to be sent
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  command error_t MacTransmit.send( message_t* ONE p_msg, bool useCca ) {
    csmaca_backoff_period = call csmacaMacParams.get_backoff();
    csmaca_min_backoff = call csmacaMacParams.get_min_backoff();
    csmaca_delay_after_receive = call csmacaMacParams.get_delay_after_receive();

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

    call RadioTransmit.load(p_msg);
    return SUCCESS;
  }

  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  command error_t MacTransmit.resend(bool useCca) {
    if (m_state == S_CANCEL) {
      return ECANCEL;
    }

    if ( m_state != S_STARTED ) {
      return FAIL;
    }

    m_cca = useCca;
    m_state = useCca ? S_SAMPLE_CCA : S_BEGIN_TRANSMIT;
    totalCcaChecks = 0;

    if(m_cca) {
      requestInitialBackoff(m_msg);
      if (myInitialBackoff) {
        call BackoffTimer.start( myInitialBackoff );
      } else {
        signal BackoffTimer.fired();
      }
    } else {
      call RadioTransmit.send(m_msg, useCca);
    }

    return SUCCESS;
  }

  command error_t MacTransmit.cancel() {
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

    return SUCCESS;
  }

  

  async event void RadioTransmit.loadDone(message_t* msg, error_t error) {
    if ( m_state == S_CANCEL ) {
      call RadioTransmit.cancel();
      m_state = S_STARTED;
      signal MacTransmit.sendDone( msg, ECANCEL );

    } else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      call RadioTransmit.send(m_msg, m_cca);
    } else {
      m_state = S_SAMPLE_CCA;

      requestInitialBackoff(msg);
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
    switch( m_state ) {
        
    case S_SAMPLE_CCA : 
      // sample CCA and wait a little longer if free, just in case we
      // sampled during the ack turn-around window
      if ( !call EnergyIndicator.isReceiving() ) {
        m_state = S_BEGIN_TRANSMIT;
        call BackoffTimer.start( CC2420_TIME_ACK_TURNAROUND );    
      } else {
        congestionBackoff(m_msg);
      }
      break;
        
    case S_BEGIN_TRANSMIT:
      call RadioTransmit.send(m_msg, m_cca);
      break;

    case S_CANCEL:
      call RadioTransmit.cancel();
      m_state = S_STARTED;
      signal MacTransmit.sendDone( m_msg, ECANCEL );
      break;
        
    default:
      break;
    }
  }
      
  async event void RadioTransmit.sendDone(error_t error) {
    if (m_state == S_CANCEL){
      m_state = S_STARTED;
      signal MacTransmit.sendDone( m_msg, ECANCEL );
    } else {
      if (error == EBUSY) {
        m_state = S_SAMPLE_CCA;
        totalCcaChecks = 0;
        congestionBackoff(m_msg);
      } else {
        m_state = S_STARTED;
        call BackoffTimer.stop();
        signal MacTransmit.sendDone( m_msg, error );


      }
    }

  }


  event void csmacaMacParams.receive_status(uint16_t status_flag) {
  }

}

