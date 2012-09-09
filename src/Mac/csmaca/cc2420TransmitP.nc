#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"

module cc2420TransmitP @safe() {

  provides interface StdControl;
  provides interface MacTransmit;
  provides interface RadioBackoff;

  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface StdControl as SubControl;
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
  

  /* -------------------------- */

  cc2420_header_t* ONE getHeader( message_t* ONE msg ) {
    return TCAST(cc2420_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( cc2420_header_t ));
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

  /**
   * Congestion Backoff
   */
  void congestionBackoff() {
    signal RadioBackoff.requestCongestionBackoff(m_msg);
    if (myCongestionBackoff) {
      call BackoffTimer.start(myCongestionBackoff);
    } else {
      signal BackoffTimer.fired();
    }
  }


  /***************** StdControl Commands ****************/
  command error_t StdControl.start() {
    call SubControl.start();
 //   call RadioStdControl.start();
    call RadioTransmit.start();
    m_state = S_STARTED;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call SubControl.stop();
 //   call RadioStdControl.stop();
    call RadioTransmit.stop();
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
  async command error_t MacTransmit.send( message_t* ONE p_msg, bool useCca ) {
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
  async command error_t MacTransmit.resend(bool useCca) {
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
      signal RadioBackoff.requestInitialBackoff(m_msg);
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

  async command error_t MacTransmit.cancel() {
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
  

  event void RadioTransmit.loadDone(message_t* msg, error_t error) {
    if ( m_state == S_CANCEL ) {
      call RadioTransmit.cancel();
      m_state = S_STARTED;
      signal MacTransmit.sendDone( msg, ECANCEL );

    } else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      call RadioTransmit.send(m_msg, m_cca);
    } else {
      m_state = S_SAMPLE_CCA;

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
      
  event void RadioTransmit.sendDone(error_t error) {
    if (m_state == S_CANCEL){
      m_state = S_STARTED;
      signal MacTransmit.sendDone( m_msg, ECANCEL );
    } else {
      if (error == EBUSY) {
        m_state = S_SAMPLE_CCA;
        totalCcaChecks = 0;
        congestionBackoff();
      } else {
        m_state = S_STARTED;
        call BackoffTimer.stop();
        signal MacTransmit.sendDone( m_msg, error );


      }
    }

  }






}

