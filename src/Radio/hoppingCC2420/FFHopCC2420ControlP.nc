#include <Ieee154.h>
#include "Timer.h"
#include "hoppingCC2420Radio.h"

#define MAX_TIMEOUTS 2

generic module FFHopCC2420ControlP(uint8_t number_of_channels,
                                                uint16_t channel_lifetime,
                                                bool speedup_receive,
						bool use_ack) @safe() {


  provides interface Init;
  provides interface Resource;
  provides interface HopCC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;

  uses interface LocalIeeeEui64;

  uses interface Alarm<T32khz,uint32_t> as StartupTimer;
  uses interface GeneralIO as CSN;
  uses interface GeneralIO as RSTN;
  uses interface GeneralIO as VREN;
  uses interface GpioInterrupt as InterruptCCA;
  uses interface ActiveMessageAddress;

  uses interface CC2420Ram as IEEEADR;
  uses interface CC2420Ram as PANID;
  uses interface CC2420Register as FSCTRL;
  uses interface CC2420Register as IOCFG0;
  uses interface CC2420Register as IOCFG1;
  uses interface CC2420Register as MDMCTRL0;
  uses interface CC2420Register as MDMCTRL1;
  uses interface CC2420Register as RXCTRL1;
  uses interface CC2420Register as RSSI;
  uses interface CC2420Register as TXCTRL;
  uses interface CC2420Strobe as SRXON;
  uses interface CC2420Strobe as SRFOFF;
  uses interface CC2420Strobe as SXOSCOFF;
  uses interface CC2420Strobe as SXOSCON;
  
  uses interface Resource as SpiResource;
  uses interface Resource as RssiResource;
  uses interface Resource as SyncResource;

  uses interface Leds;
  uses interface Timer<TMilli> as ChannelTimeout;
}

implementation {

  uint8_t channel_timeouts;

  typedef enum {
    S_VREG_STOPPED,
    S_VREG_STARTING,
    S_VREG_STARTED,
    S_XOSC_STARTING,
    S_XOSC_STARTED,
  } cc2420_control_state_t;

  uint8_t def_power = 31;

  uint8_t m_tx_power;
  
  uint16_t m_pan;
  
  uint16_t m_short_addr;

  ieee_eui64_t m_ext_addr;
  
  bool m_sync_busy;
  
  /** TRUE if acknowledgments are enabled */
  bool autoAckEnabled;
  
  /** TRUE if acknowledgments are generated in hardware only */
  bool hwAutoAckDefault;
  
  /** TRUE if software or hardware address recognition is enabled */
  bool addressRecognition;
  
  /** TRUE if address recognition should also be performed in hardware */
  bool hwAddressRecognition;
  
  norace cc2420_control_state_t m_state = S_VREG_STOPPED;

  norace uint8_t channel_index = 0;
  
  /***************** Prototypes ****************/

  void writeFsctrl();
  void writeMdmctrl0();
  void writeId();
  void writeTxctrl();

  task void sync();
  task void syncDone();
    
  /***************** Init Commands ****************/
  command error_t Init.init() {
    int i, t;
    call CSN.makeOutput();
    call RSTN.makeOutput();
    call VREN.makeOutput();
    channel_index = 0;
    
    m_short_addr = call ActiveMessageAddress.amAddress();
    m_ext_addr = call LocalIeeeEui64.getId();
    m_pan = call ActiveMessageAddress.amGroup();
    m_tx_power = def_power;
    
    m_ext_addr = call LocalIeeeEui64.getId();
    for (i = 0; i < 4; i++) {
      t = m_ext_addr.data[i];
      m_ext_addr.data[i] = m_ext_addr.data[7-i];
      m_ext_addr.data[7-i] = t;
    }


#if defined(CC2420_NO_ADDRESS_RECOGNITION)
    addressRecognition = FALSE;
#else
    addressRecognition = TRUE;
#endif
    
#if defined(CC2420_HW_ADDRESS_RECOGNITION)
    hwAddressRecognition = TRUE;
#else
    hwAddressRecognition = FALSE;
#endif
    
    
#if defined(CC2420_NO_ACKNOWLEDGEMENTS)
    autoAckEnabled = FALSE;
#else
    autoAckEnabled = TRUE;
#endif
    
#if defined(CC2420_HW_ACKNOWLEDGEMENTS)
    hwAutoAckDefault = TRUE;
    hwAddressRecognition = TRUE;
#else
    hwAutoAckDefault = FALSE;
#endif
    
    
    return SUCCESS;
  }

  /***************** Resource Commands ****************/
  async command error_t Resource.immediateRequest() {
    error_t error = call SpiResource.immediateRequest();
    if ( error == SUCCESS ) {
      call CSN.clr();
    }
    return error;
  }

  async command error_t Resource.request() {
    return call SpiResource.request();
  }

  async command bool Resource.isOwner() {
    return call SpiResource.isOwner();
  }

  async command error_t Resource.release() {
    atomic {
      call CSN.set();
      return call SpiResource.release();
    }
  }

  /***************** CC2420Power Commands ****************/
  async command error_t CC2420Power.startVReg() {
    atomic {
      if ( m_state != S_VREG_STOPPED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTING;
    }
    call VREN.set();
    call StartupTimer.start( CC2420_TIME_VREN );
    return SUCCESS;
  }

  async command error_t CC2420Power.stopVReg() {
    m_state = S_VREG_STOPPED;
    call RSTN.clr();
    call VREN.clr();
    call RSTN.set();
    return SUCCESS;
  }

  async command error_t CC2420Power.startOscillator() {
    atomic {
      if ( m_state != S_VREG_STARTED ) {
        return FAIL;
      }
        
      m_state = S_XOSC_STARTING;
      call IOCFG1.write( CC2420_SFDMUX_XOSC16M_STABLE << 
                         CC2420_IOCFG1_CCAMUX );
                         
      call InterruptCCA.enableRisingEdge();
      call SXOSCON.strobe();
      
      call IOCFG0.write( ( 1 << CC2420_IOCFG0_FIFOP_POLARITY ) |
          ( 127 << CC2420_IOCFG0_FIFOP_THR ) );
                         
      writeFsctrl();
      writeMdmctrl0();
  
      call RXCTRL1.write( ( 1 << CC2420_RXCTRL1_RXBPF_LOCUR ) |
          ( 1 << CC2420_RXCTRL1_LOW_LOWGAIN ) |
          ( 1 << CC2420_RXCTRL1_HIGH_HGM ) |
          ( 1 << CC2420_RXCTRL1_LNA_CAP_ARRAY ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_TAIL ) |
          ( 1 << CC2420_RXCTRL1_RXMIX_VCM ) |
          ( 2 << CC2420_RXCTRL1_RXMIX_CURRENT ) );

      writeTxctrl();
    }
    return SUCCESS;
  }


  async command error_t CC2420Power.stopOscillator() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      m_state = S_VREG_STARTED;
      call SXOSCOFF.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rxOn() {
    atomic {
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      call SRXON.strobe();
    }
    return SUCCESS;
  }

  async command error_t CC2420Power.rfOff() {
    atomic {  
      if ( m_state != S_XOSC_STARTED ) {
        return FAIL;
      }
      call SRFOFF.strobe();
    }
    return SUCCESS;
  }

  
  /***************** HopCC2420Config Commands ****************/
  command uint8_t HopCC2420Config.getChannel() {
    atomic return channels[channel_index];
  }

  command void HopCC2420Config.setChannel( uint8_t channel ) {
  }

  command void HopCC2420Config.nextChannel() {
    channel_timeouts = MAX_TIMEOUTS; 
    channel_index = (channel_index + 1) % number_of_channels;
    call HopCC2420Config.sync();
    call ChannelTimeout.startOneShot(channel_lifetime);
  }

  command void HopCC2420Config.resetChannel() {
    channel_index = 0;
    call HopCC2420Config.sync();
  }

  command ieee_eui64_t HopCC2420Config.getExtAddr() {
    return m_ext_addr;
  }

  async command uint16_t HopCC2420Config.getShortAddr() {
    atomic return m_short_addr;
  }

  command void HopCC2420Config.setShortAddr( uint16_t addr ) {
    atomic m_short_addr = addr;
  }

  async command uint16_t HopCC2420Config.getPanAddr() {
    atomic return m_pan;
  }

  command void HopCC2420Config.setPanAddr( uint16_t pan ) {
    atomic m_pan = pan;
  }

  /**
   * Sync must be called to commit software parameters configured on
   * the microcontroller (through the HopCC2420Config interface) to the
   * CC2420 radio chip.
   */
  command error_t HopCC2420Config.sync() {
    atomic {
      if ( m_sync_busy ) {
        dbgs(F_RADIO, S_NONE, DBGS_SYNC_PARAMS_FAIL, channels[channel_index], channels[channel_index]);
        return FAIL;
      }
      
      m_sync_busy = TRUE;
      if ( m_state == S_XOSC_STARTED ) {
        call SyncResource.request();
      } else {
        post syncDone();
      }
    }
    return SUCCESS;
  }

  /**
   * @param enableAddressRecognition TRUE to turn address recognition on
   * @param useHwAddressRecognition TRUE to perform address recognition first
   *     in hardware. This doesn't affect software address recognition. The
   *     driver must sync with the chip after changing this value.
   */
  command void HopCC2420Config.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
    atomic {
      addressRecognition = enableAddressRecognition;
      hwAddressRecognition = useHwAddressRecognition;
    }
  }
  
  /**
   * @return TRUE if address recognition is enabled
   */
  async command bool HopCC2420Config.isAddressRecognitionEnabled() {
    atomic return addressRecognition;
  }
  
  /**
   * @return TRUE if address recognition is performed first in hardware.
   */
  async command bool HopCC2420Config.isHwAddressRecognitionDefault() {
    atomic return hwAddressRecognition;
  }
  
  
  /**
   * Sync must be called for acknowledgement changes to take effect
   * @param enableAutoAck TRUE to enable auto acknowledgements
   * @param hwAutoAck TRUE to default to hardware auto acks, FALSE to
   *     default to software auto acknowledgements
   */
  command void HopCC2420Config.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
    atomic autoAckEnabled = enableAutoAck;
    atomic hwAutoAckDefault = hwAutoAck;
  }
  
  /**
   * @return TRUE if hardware auto acks are the default, FALSE if software
   *     acks are the default
   */
  async command bool HopCC2420Config.isHwAutoAckDefault() {
    atomic return hwAutoAckDefault;    
  }
  
  /**
   * @return TRUE if auto acks are enabled
   */
  async command bool HopCC2420Config.isAutoAckEnabled() {
    atomic return autoAckEnabled;
  }
  
  /***************** ReadRssi Commands ****************/
  command error_t ReadRssi.read() { 
    return call RssiResource.request();
  }
  
  /***************** Spi Resources Events ****************/
  event void SyncResource.granted() {
    call CSN.clr();
    call SRFOFF.strobe();
    writeFsctrl();
    writeMdmctrl0();
    writeId();
    call CSN.set();
    call CSN.clr();
    call SRXON.strobe();
    call CSN.set();
    call SyncResource.release();

    dbgs(F_RADIO, S_NONE, DBGS_SYNC_PARAMS, channels[channel_index], channels[channel_index]);

    post syncDone();
  }

  event void SpiResource.granted() {
    call CSN.clr();
    signal Resource.granted();
  }

  event void RssiResource.granted() { 
    uint16_t data = 0;
    call CSN.clr();
    call RSSI.read(&data);
    call CSN.set();
    
    call RssiResource.release();
    data += 0x7f;
    data &= 0x00ff;
    signal ReadRssi.readDone(SUCCESS, data); 
  }
  
  /***************** StartupTimer Events ****************/
  async event void StartupTimer.fired() {
    if ( m_state == S_VREG_STARTING ) {
      m_state = S_VREG_STARTED;
      call RSTN.clr();
      call RSTN.set();
      signal CC2420Power.startVRegDone();
    }
  }

  /***************** InterruptCCA Events ****************/
  async event void InterruptCCA.fired() {
    m_state = S_XOSC_STARTED;
    call InterruptCCA.disable();
    call IOCFG1.write( 0 );
    writeId();
    call CSN.set();
    call CSN.clr();
    signal CC2420Power.startOscillatorDone();
  }
 
  /***************** ActiveMessageAddress Events ****************/
  async event void ActiveMessageAddress.changed() {
    atomic {
      m_short_addr = call ActiveMessageAddress.amAddress();
      m_pan = call ActiveMessageAddress.amGroup();
    }
    
    post sync();
  }
  
  /***************** Tasks ****************/
  /**
   * Attempt to synchronize our current settings with the CC2420
   */

  task void sync() {
    call HopCC2420Config.sync();
  }
  
  task void syncDone() {
    atomic m_sync_busy = FALSE;
    signal HopCC2420Config.syncDone( SUCCESS );
  }
  
  
  /***************** Functions ****************/
  /**
   * Write teh FSCTRL register
   */
  void writeFsctrl() {
    call FSCTRL.write( ( 1 << CC2420_FSCTRL_LOCK_THR ) |
          ( ( (channels[channel_index] - 11)*5+357 ) << CC2420_FSCTRL_FREQ ) );
  }

  /**
   * Write the MDMCTRL0 register
   * Disabling hardware address recognition improves acknowledgment success
   * rate and low power communications reliability by causing the local node
   * to do work while the real destination node of the packet is acknowledging.
   */
  void writeMdmctrl0() {
    atomic {
      call MDMCTRL0.write( ( 1 << CC2420_MDMCTRL0_RESERVED_FRAME_MODE ) |
          ( ((addressRecognition && hwAddressRecognition) ? 1 : 0) << CC2420_MDMCTRL0_ADR_DECODE ) |
          ( 2 << CC2420_MDMCTRL0_CCA_HYST ) |
          ( 3 << CC2420_MDMCTRL0_CCA_MOD ) |
          ( 1 << CC2420_MDMCTRL0_AUTOCRC ) |
          ( (autoAckEnabled && hwAutoAckDefault) << CC2420_MDMCTRL0_AUTOACK ) |
          ( 0 << CC2420_MDMCTRL0_AUTOACK ) |
          ( 2 << CC2420_MDMCTRL0_PREAMBLE_LENGTH ) );
    }
    // Jon Green:
    // MDMCTRL1.CORR_THR is defaulted to 20 instead of 0 like the datasheet says
    // If we add in changes to MDMCTRL1, be sure to include this fix.
  }
  
  /**
   * Write the PANID register
   */
  void writeId() {
    nxle_uint16_t id[ 6 ];

    atomic {
      /* Eui-64 is stored in big endian */
      memcpy((uint8_t *)id, m_ext_addr.data, 8);
      id[ 4 ] = m_pan;
      id[ 5 ] = m_short_addr;
    }

    call IEEEADR.write(0, (uint8_t *)&id, 12);
  }

  /* Write the Transmit control register. This
     is needed so acknowledgments are sent at the
     correct transmit power even if a node has
     not sent a packet (Google Code Issue #27) -pal */

  void writeTxctrl() {
    atomic {
      call TXCTRL.write( ( 2 << CC2420_TXCTRL_TXMIXBUF_CUR ) |
			 ( 3 << CC2420_TXCTRL_PA_CURRENT ) |
			 ( 1 << CC2420_TXCTRL_RESERVED ) |
			 ( (def_power & 0x1F) << CC2420_TXCTRL_PA_LEVEL ) );
    }
  }

  event void ChannelTimeout.fired() {
    --channel_timeouts;
 
    if (channel_timeouts) {
      dbgs(F_RADIO, S_NONE, DBGS_CHANNEL_TIMEOUT_NEXT, channels[channel_index], channels[channel_index]);
      channel_index = (channel_index + 1) % number_of_channels;
      call HopCC2420Config.sync();
      call ChannelTimeout.startOneShot(channel_lifetime);
    } else {
      dbgs(F_RADIO, S_NONE, DBGS_CHANNEL_TIMEOUT_RESET, channels[channel_index], channels[channel_index]);
      call ChannelTimeout.stop();
      call HopCC2420Config.resetChannel();
    }
  }

  /***************** Defaults ****************/
  default event void HopCC2420Config.syncDone( error_t error ) {
  }

  default event void ReadRssi.readDone(error_t error, uint16_t data) {
  }
  
}
