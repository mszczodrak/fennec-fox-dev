#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"
#include "Fennec.h"
#include "cuMac.h"

module cuTransmitP @safe() {
  provides interface cuTransmit;
  provides interface SplitControl;
  provides interface Send;

  uses interface Alarm<T32khz,uint32_t> as BackoffTimer;
  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioBuffer;
  uses interface RadioSend;
  uses interface RadioPacket;
  uses interface SplitControl as RadioControl;
  uses interface cuMacParams;
  uses interface Random;
  uses interface State as SplitControlState;
  uses interface RadioPower;
  uses interface Resource as RadioResource;
}

implementation {

  norace message_t * ONE_NOK m_msg;
  norace bool m_cca;
  norace uint8_t m_state = S_STOPPED;
  norace uint16_t cu_backoff_period;
  norace uint16_t cu_min_backoff;
  norace uint16_t cu_delay_after_receive;
  norace bool radio_status = 0;

  norace error_t sendDoneErr;

  enum {
    S_STOPPED,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
    S_TRANSMITTING,
  };

  error_t sendErr = SUCCESS;

  /** TRUE if we are to use CCA when sending the current packet */
  norace bool ccaOn;

  /****************** Prototypes ****************/
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();
  task void signalSendDone();

  void start_loading() {
    if( call RadioBuffer.load(m_msg) != SUCCESS) {
      sendDoneErr = FAIL;
      post signalSendDone();
    }
  }

  void shutdown();

  task void signalSendDone() {
    m_state = S_STARTED;
    atomic sendErr = sendDoneErr;
    post sendDone_task();
  }

  /** Total CCA checks that showed no activity before the NoAck LPL send */
  norace int8_t totalCcaChecks;
  
  /** The initial backoff period */
  norace uint16_t myInitialBackoff;
  
  /** The congestion backoff period */
  norace uint16_t myCongestionBackoff;


  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {

    if(call SplitControlState.requestState(S_STARTING) == SUCCESS) {
      if (call SplitControlState.isState(S_STARTING)) {
        post startDone_task();
      }

      return SUCCESS;
    } else if(call SplitControlState.isState(S_STARTED)) {
      return EALREADY;

    } else if(call SplitControlState.isState(S_STARTING)) {
      return SUCCESS;
    }

    return EBUSY;
  }

  command error_t SplitControl.stop() {
    if (call SplitControlState.isState(S_STARTED)) {
      call SplitControlState.forceState(S_STOPPING);
      shutdown();
      return SUCCESS;

    } else if(call SplitControlState.isState(S_STOPPED)) {
      return EALREADY;

    } else if(call SplitControlState.isState(S_TRANSMITTING)) {
      call SplitControlState.forceState(S_STOPPING);
      // At sendDone, the radio will shut down
      return SUCCESS;

    } else if(call SplitControlState.isState(S_STOPPING)) {
      return SUCCESS;
    }

    return EBUSY;
  }

  /***************** Send Commands ****************/
  command error_t Send.cancel( message_t* p_msg ) {
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

  command error_t Send.send( message_t* p_msg, uint8_t len ) {

    cu_header_t* header = (cu_header_t*) call Send.getPayload( p_msg, len);
    metadata_t* metadata = (metadata_t*) p_msg->metadata;


    if ((!call cuMacParams.get_ack()) && (header->fcf & 1 << IEEE154_FCF_ACK_REQ)) {
      header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
    }

    atomic {
      if (!call SplitControlState.isState(S_STARTED)) {
        return FAIL;
      }

      call SplitControlState.forceState(S_TRANSMITTING);
      m_msg = p_msg;
    }

#ifdef CC2420_HW_SECURITY
    header->fcf &= ((1 << IEEE154_FCF_ACK_REQ)|
                    (1 << IEEE154_FCF_SECURITY_ENABLED)|
                    (0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
                    (0x3 << IEEE154_FCF_DEST_ADDR_MODE));
#else
    header->fcf &= ((1 << IEEE154_FCF_ACK_REQ) |
                    (0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
                    (0x3 << IEEE154_FCF_DEST_ADDR_MODE));
#endif
    header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
                     ( 1 << IEEE154_FCF_INTRAPAN ) );

    metadata->ack = !call cuMacParams.get_ack();
    metadata->rssi = 0;
    metadata->lqi = 0;
    //metadata->timesync = FALSE;
    metadata->timestamp = INVALID_TIMESTAMP;

    cu_backoff_period = call cuMacParams.get_backoff();
    cu_min_backoff = call cuMacParams.get_min_backoff();

    if (m_state == S_CANCEL) {
      return ECANCEL;
    }

    if ( m_state != S_STARTED ) {
      return FAIL;
    }

    atomic {
      m_state = S_LOAD;
      m_cca = call cuMacParams.get_cca();
      m_msg = m_msg;
      totalCcaChecks = 0;
    
      if (radio_status == 1) {
        start_loading();
      }
    }
    return SUCCESS;
  }

  command void* Send.getPayload(message_t* m, uint8_t len) {
    return call RadioPacket.getPayload(m, len);
  }

  command uint8_t Send.maxPayloadLength() {
    return call RadioPacket.maxPayloadLength();
  }

  async event void RadioPower.startVRegDone() {}

  event void RadioResource.granted() {}

  async event void RadioPower.startOscillatorDone() {}

  /***************** Tasks ****************/
  task void sendDone_task() {
    error_t packetErr;
    atomic packetErr = sendErr;
    if(call SplitControlState.isState(S_STOPPING)) {
      shutdown();

    } else {
      call SplitControlState.forceState(S_STARTED);
    }

    signal Send.sendDone( m_msg, packetErr );
  }

  task void startDone_task() {
    cu_backoff_period = call cuMacParams.get_backoff();
    cu_min_backoff = call cuMacParams.get_min_backoff();

    m_state = S_STARTED;

    call SplitControlState.forceState(S_STARTED);
    signal SplitControl.startDone( SUCCESS );
  }

  task void stopDone_task() {
    call SplitControlState.forceState(S_STOPPED);
    signal SplitControl.stopDone( SUCCESS );
  }


  /***************** Functions ****************/
  /**
   * Shut down all sub-components and turn off the radio
   */
  void shutdown() {
    m_state = S_STOPPED;
    call BackoffTimer.stop();
    post stopDone_task();
  }


  void requestInitialBackoff(message_t *msg) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    if ((cu_delay_after_receive > 0) && (metadata->rxInterval > 0)) {
      myInitialBackoff = ( call Random.rand16() % (0x4 * cu_backoff_period) + cu_min_backoff);
    } else {
      myInitialBackoff = ( call Random.rand16() % (0x1F * cu_backoff_period) + cu_min_backoff);
    }
  }

  void congestionBackoff(message_t *msg) {
    metadata_t* metadata = (metadata_t*) msg->metadata;
    if ((cu_delay_after_receive > 0) && (metadata->rxInterval > 0)) {
      myCongestionBackoff = ( call Random.rand16() % (0x3 * cu_backoff_period) + cu_min_backoff);
    } else {
      myCongestionBackoff = ( call Random.rand16() % (0x7 * cu_backoff_period) + cu_min_backoff);
    }

    if (myCongestionBackoff) {
      call BackoffTimer.start(myCongestionBackoff);
    } else {
      signal BackoffTimer.fired();
    }
  }

  /**
   * Resend a packet that already exists in the outbound tx buffer on the
   * chip
   * @param cca TRUE if this transmit should use clear channel assessment
   */
  command error_t cuTransmit.resend(message_t *msg, bool useCca) {
    if (m_msg != msg) {
      return FAIL;
    }

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
      if (call RadioSend.send(m_msg, useCca) != SUCCESS) {
        signal RadioSend.sendDone(m_msg, FAIL);
        return FAIL;
      }
    }
    return SUCCESS;
  }

  async event void RadioBuffer.loadDone(message_t* msg, error_t error) {
    if (error != SUCCESS) {
      sendDoneErr = error;
      post signalSendDone();
      return;
    }

    if ( m_state == S_CANCEL ) {
      call RadioSend.cancel(msg);
      sendDoneErr = ECANCEL;
      post signalSendDone();

    } else if ( !m_cca ) {
      m_state = S_BEGIN_TRANSMIT;
      if (call RadioSend.send(m_msg, m_cca) != SUCCESS) {
        signal RadioSend.sendDone(m_msg, FAIL);
      }
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
        call BackoffTimer.start( TIME_ACK_TURNAROUND );    
      } else {
        congestionBackoff(m_msg);
      }
      break;
        
    case S_BEGIN_TRANSMIT:
      if (call RadioSend.send(m_msg, m_cca) != SUCCESS) {
        signal RadioSend.sendDone(m_msg, FAIL);
      }
      break;

    case S_CANCEL:
      call RadioSend.cancel(m_msg);
      m_state = S_STARTED;
      sendDoneErr = ECANCEL;
      post signalSendDone();
      break;
        
    default:
      break;
    }
  }
      
  async event void RadioSend.sendDone(message_t *msg, error_t error) {
    if (m_state == S_CANCEL){
      sendDoneErr = ECANCEL;
      post signalSendDone();
    } else {
      if (error == EBUSY) {
        m_state = S_SAMPLE_CCA;
        totalCcaChecks = 0;
        congestionBackoff(m_msg);
      } else {
        call BackoffTimer.stop();
        sendDoneErr = error;
        post signalSendDone();
      }
    }
  }

  event void RadioControl.startDone( error_t err) {
    radio_status = 1;
    if (m_state == S_LOAD) {
      start_loading();
    }
  }

  event void RadioControl.stopDone( error_t err) {
    radio_status = 0;
    if ((m_state == S_LOAD) || (m_state == S_SAMPLE_CCA) || (m_state == S_BEGIN_TRANSMIT)) {
      sendDoneErr = FAIL;
      post signalSendDone();
    }
  }

}

