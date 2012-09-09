/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.12 $ $Date: 2009/09/17 23:36:36 $
 */

#include "Fennec.h"
#include "message.h"

module CsmaP @safe() {

  provides interface SplitControl;
  provides interface Send;

  uses interface Resource as RadioResource;
  uses interface StdControl as SubControl;
  uses interface MacTransmit;
  uses interface State as SplitControlState;

  uses interface RadioPower;

  uses interface csmacaMacParams;
}

implementation {

  enum {
    S_STOPPED,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
    S_TRANSMITTING,
  };

  message_t* ONE_NOK m_msg;
  
  error_t sendErr = SUCCESS;
 
  /** TRUE if we are to use CCA when sending the current packet */
  norace bool ccaOn;
  
  /****************** Prototypes ****************/
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();
  
  void shutdown();

  csmaca_header_t* ONE getHeader( message_t* ONE msg ) {
    return TCAST(csmaca_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( csmaca_header_t ));
  }



  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {

    if(call SplitControlState.requestState(S_STARTING) == SUCCESS) {
      call RadioPower.startVReg();
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
    return call MacTransmit.cancel();
  }

  command error_t Send.send( message_t* p_msg, uint8_t len ) {
    
    csmaca_header_t* header = getHeader( p_msg );
    metadata_t* metadata = (metadata_t*) p_msg->metadata;

    if ((!call csmacaMacParams.get_ack()) && (header->fcf & 1 << IEEE154_FCF_ACK_REQ)) {
      header->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
    }

    atomic {
      if (!call SplitControlState.isState(S_STARTED)) {
        return FAIL;
      }
      
      call SplitControlState.forceState(S_TRANSMITTING);
      m_msg = p_msg;
    }

    // header->length = len + CC2420_SIZE;
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

    metadata->ack = !call csmacaMacParams.get_ack();
    metadata->rssi = 0;
    metadata->lqi = 0;
    //metadata->timesync = FALSE;
    metadata->timestamp = CC2420_INVALID_TIMESTAMP;

    ccaOn = call csmacaMacParams.get_cca();

    call MacTransmit.send( m_msg, ccaOn );
    return SUCCESS;

  }

  command void* Send.getPayload(message_t* m, uint8_t len) {
    if (len <= call Send.maxPayloadLength()) {
      return (void* COUNT_NOK(len ))(m->data);
    }
    else {
      return NULL;
    }
  }

  command uint8_t Send.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  /**************** Events ****************/
  async event void MacTransmit.sendDone( message_t* p_msg, error_t err ) {
    atomic sendErr = err;
    post sendDone_task();
  }

  task void resource_request() {
    call RadioResource.request();
  }

  async event void RadioPower.startVRegDone() {
    post resource_request();
  }
  
  event void RadioResource.granted() {
    call RadioPower.startOscillator();
  }

  async event void RadioPower.startOscillatorDone() {
    post startDone_task();
  }
  
  
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
    call SubControl.start();
    call RadioPower.rxOn();
    call RadioResource.release();
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
    call SubControl.stop();
    call RadioPower.stopVReg();
    post stopDone_task();
  }

  /***************** Defaults ***************/
  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }

  event void csmacaMacParams.receive_status(uint16_t status_flag) {
  }
  
  
}

