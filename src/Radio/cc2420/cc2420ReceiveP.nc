#include "IEEE802154.h"
#include "message.h"
#include "AM.h"
#include "Fennec.h"

module cc2420ReceiveP @safe() {

provides interface Init;
provides interface StdControl;
provides interface CC2420Receive;
provides interface Receive;
provides interface ReceiveIndicator as PacketIndicator;

uses interface GeneralIO as CSN;
uses interface GeneralIO as FIFO;
uses interface GeneralIO as FIFOP;
uses interface GpioInterrupt as InterruptFIFOP;

uses interface Resource as SpiResource;
uses interface CC2420Fifo as RXFIFO;
uses interface CC2420Strobe as SACK;
uses interface CC2420Strobe as SFLUSHRX;
uses interface RadioConfig;
uses interface RadioPacket;

uses interface CC2420Strobe as SRXDEC;
uses interface CC2420Register as SECCTRL0;
uses interface CC2420Register as SECCTRL1;
uses interface CC2420Ram as KEY0;
uses interface CC2420Ram as KEY1;
uses interface CC2420Ram as RXNONCE;
uses interface CC2420Ram as RXFIFO_RAM;
uses interface CC2420Strobe as SNOP;

uses interface Leds;
}

implementation {

  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    SACK_HEADER_LENGTH = 7,
  };

  uint32_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];

  uint8_t m_timestamp_head;
  
  uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
  uint8_t m_missed_packets;

  /** TRUE if we are receiving a valid packet into the stack */
  bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  norace uint8_t m_bytes_left;
  
  norace message_t* ONE_NOK m_p_rx_buf;

  message_t m_rx_buf;
  fennec_state_t m_state;

  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  bool passesAddressCheck(message_t * ONE msg);

  task void receiveDone_task();

  /***************** Init Commands ****************/
  command error_t Init.init() {
    m_p_rx_buf = &m_rx_buf;
    return SUCCESS;
  }

  /***************** StdControl ****************/
  command error_t StdControl.start() {
    atomic {
      reset_state();
      m_state = S_STARTED;
      atomic receivingPacket = FALSE;
      /* Note:
         We use the falling edge because the FIFOP polarity is reversed. 
         This is done in CC2420Power.startOscillator from CC2420ControlP.nc.
       */
      call InterruptFIFOP.enableFallingEdge();
    }
    return SUCCESS;
  }
  
  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      reset_state();
      call CSN.set();
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }

  /***************** CC2420Receive Commands ****************/
  /**
   * Start frame delimiter signifies the beginning/end of a packet
   * See the CC2420 datasheet for details.
   */
  async command void CC2420Receive.sfd( uint32_t rtime ) {
    if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
      uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
                        TIMESTAMP_QUEUE_SIZE );
      m_timestamp_queue[ tail ] = rtime;
      m_timestamp_size++;
    }
  }

  async command void CC2420Receive.sfd_dropped() {
    if ( m_timestamp_size ) {
      m_timestamp_size--;
    }
  }

  /***************** PacketIndicator Commands ****************/
  async command bool PacketIndicator.isReceiving() {
    bool receiving;
    atomic {
      receiving = receivingPacket;
    }
    return receiving;
  }
  
  
  /***************** InterruptFIFOP Events ****************/
  async event void InterruptFIFOP.fired() {
    if ( m_state == S_STARTED ) {
      m_state = S_RX_LENGTH;
      beginReceive();
    } else {
      m_missed_packets++;
    }
  }

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    receive();
  }
 

  bool quick_dest_check(message_t *msg) {
    cc2420_hdr_t* header = (cc2420_hdr_t*) call RadioPacket.getPayload( msg, sizeof(cc2420_hdr_t) );
    return ((header->dest == call RadioConfig.getShortAddr()) || (header->dest == AM_BROADCAST_ADDR));
  }

 
  /***************** RXFIFO Events ****************/
  /**
   * We received some bytes from the SPI bus.  Process them in the context
   * of the state we're in.  Remember the length byte is not part of the length
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,
                                    error_t error ) {
    cc2420_hdr_t* header = (cc2420_hdr_t*)call RadioPacket.getPayload( m_p_rx_buf, sizeof(cc2420_hdr_t) );
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2420_hdr_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);
    rxFrameLength = buf[ 0 ];

    switch( m_state ) {

    case S_RX_LENGTH:
      m_state = S_RX_FCF;
      if ( rxFrameLength + 1 > m_bytes_left
           ) {
        // Length of this packet is bigger than the RXFIFO, flush it out.
        flush();
        
      } else {
        if ( !call FIFO.get() && !call FIFOP.get() ) {
          m_bytes_left -= rxFrameLength + 1;
        }
        
        if(rxFrameLength <= CC2420_MAX_MESSAGE_SIZE) {
          if(rxFrameLength > 0) {
            if(rxFrameLength > SACK_HEADER_LENGTH) {
              // This packet has an FCF byte plus at least one more byte to read
              call RXFIFO.continueRead(buf + 1, SACK_HEADER_LENGTH);
              
            } else {
              // This is really a bad packet, skip FCF and get it out of here.
              m_state = S_RX_PAYLOAD;
              call RXFIFO.continueRead(buf + 1, rxFrameLength);
            }
                            
          } else {
            // Length == 0; start reading the next packet
            atomic receivingPacket = FALSE;
            call CSN.set();
            call SpiResource.release();
            waitForNextPacket();
          }
          
        } else {
          // Length is too large; we have to flush the entire Rx FIFO
          flush();
        }
      }
      break;
      
    case S_RX_FCF:
      m_state = S_RX_PAYLOAD;
      
      /*
       * The destination address check here is not completely optimized. If you 
       * are seeing issues with dropped acknowledgements, try removing
       * the address check and decreasing SACK_HEADER_LENGTH to 2.
       * The length byte and the FCF byte are the only two bytes required
       * to know that the packet is valid and requested an ack.  The destination
       * address is useful when we want to sniff packets from other transmitters
       * while acknowledging packets that were destined for our local address.
       */
      if(call RadioConfig.isAutoAckEnabled() && !call RadioConfig.isHwAutoAckDefault()) {
        if (((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1)
            && (quick_dest_check( m_p_rx_buf ))
            && ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA)) {
          // CSn flippage cuts off our FIFO; SACK and begin reading again
          call CSN.set();
          call CSN.clr();
          call SACK.strobe();
          call CSN.set();
          call CSN.clr();
	  call RXFIFO.beginRead(buf + 1 + SACK_HEADER_LENGTH,
				rxFrameLength - SACK_HEADER_LENGTH);
          return;
        }
      }
      // Didn't flip CSn, we're ok to continue reading.
      call RXFIFO.continueRead(buf + 1 + SACK_HEADER_LENGTH, 
			       rxFrameLength - SACK_HEADER_LENGTH);
      break;

    case S_RX_PAYLOAD:

      call CSN.set();
      if(!m_missed_packets) {
        // Release the SPI only if there are no more frames to download
        call SpiResource.release();
      }
      
      //new packet is buffered up, or we don't have timestamp in fifo, or ack
      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get()
            || !m_timestamp_size
            || rxFrameLength <= 10) {
        PacketTimeStampclear(m_p_rx_buf);
      }
      else {
          if (m_timestamp_size==1)
            PacketTimeStampset(m_p_rx_buf, m_timestamp_queue[ m_timestamp_head ]);
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;

          if (m_timestamp_size>0) {
            PacketTimeStampclear(m_p_rx_buf);
            m_timestamp_head = 0;
            m_timestamp_size = 0;
          }
      }

      // We may have received an ack that should be processed by Transmit
      // buf[rxFrameLength] >> 7 checks the CRC
      if ( ( buf[ rxFrameLength ] >> 7 ) && rx_buf ) {
        uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;
        signal CC2420Receive.receive( type, m_p_rx_buf );
        if ( type == IEEE154_TYPE_DATA ) {
          post receiveDone_task();
          return;
        }
      }
      
      waitForNextPacket();
      break;

    default:
      atomic receivingPacket = FALSE;
      call CSN.set();
      call SpiResource.release();
      break;
      
    }
    
  }

 
/***************** Tasks *****************/
/**
 * Fill in metadata details, pass the packet up the stack, and
 * get the next packet.
 */
task void receiveDone_task() {
    metadata_t* metadata = (metadata_t*)getMetadata( m_p_rx_buf );
    cc2420_hdr_t* header = (cc2420_hdr_t*)call RadioPacket.getPayload( m_p_rx_buf, sizeof(cc2420_hdr_t));
    uint8_t tmpLen __DEPUTY_UNUSED__ = sizeof(message_t) - (offsetof(message_t, data) - sizeof(cc2420_hdr_t));
    uint8_t* COUNT(tmpLen) buf = TCAST(uint8_t* COUNT(tmpLen), header);

    metadata->crc = buf[ header->length ] >> 7;
    metadata->lqi = buf[ header->length ] & 0x7f;
    metadata->rssi = buf[ header->length - 1 ];

    if (((!(call RadioConfig.isAddressRecognitionEnabled())) || (passesAddressCheck(m_p_rx_buf)) ) && header->length >= CC2420_SIZE) {
      /* set conf before signaling receive */
      m_p_rx_buf->conf = header->destpan;

      header->length -= CC2420_FOOTER;
	

      m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, header->length);
    }
    atomic receivingPacket = FALSE;
    waitForNextPacket();
}

  /****************** RadioConfig Events ****************/
  event void RadioConfig.syncDone( error_t error ) {
  }
  
  /****************** Functions ****************/
  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
  void beginReceive() { 
    m_state = S_RX_LENGTH;
    atomic receivingPacket = TRUE;
    if(call SpiResource.isOwner()) {
      receive();
      
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();
      
    } else {
      call SpiResource.request();
    }
  }
  
  /**
   * Flush out the Rx FIFO
   */
  void flush() {
    reset_state();

    call CSN.set();
    call CSN.clr();
    call SFLUSHRX.strobe();
    call SFLUSHRX.strobe();
    call CSN.set();
    call SpiResource.release();
    waitForNextPacket();
  }
  
  /**
   * The first byte of each packet is the length byte.  Read in that single
   * byte, and then read in the rest of the packet.  The CC2420 could contain
   * multiple packets that have been buffered up, so if something goes wrong, 
   * we necessarily want to flush out the FIFO unless we have to.
   */
  void receive() {
    call CSN.clr();
    call RXFIFO.beginRead( (uint8_t*)(call RadioPacket.getPayload( m_p_rx_buf, sizeof(cc2420_hdr_t) )), 1 );
  }


  /**
   * Determine if there's a packet ready to go, or if we should do nothing
   * until the next packet arrives
   */
  void waitForNextPacket() {
    atomic {
      if ( m_state == S_STOPPED ) {
        call SpiResource.release();
        return;
      }
      
      atomic receivingPacket = FALSE;
      
      /*
       * The FIFOP pin here is high when there are 0 bytes in the RX FIFO
       * and goes low as soon as there are bytes in the RX FIFO.  The pin
       * is inverted from what the datasheet says, and its threshold is 127.
       * Whenever the FIFOP line goes low, as you can see from the interrupt
       * handler elsewhere in this module, it means we received a new packet.
       * If the line stays low without generating an interrupt, that means
       * there's still more data to be received.
       */

      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get() ) {
        // A new packet is buffered up and ready to go
        if ( m_missed_packets ) {
          m_missed_packets--;
        }
	beginReceive();

      } else {
        // Wait for the next packet to arrive
        m_state = S_STARTED;
        m_missed_packets = 0;
        call SpiResource.release();
      }
    }
  }
  
  /**
   * Reset this component
   */
  void reset_state() {
    m_bytes_left = RXFIFO_SIZE;
    atomic receivingPacket = FALSE;
    m_timestamp_head = 0;
    m_timestamp_size = 0;
    m_missed_packets = 0;
  }

  /**
   * @return TRUE if the given message passes address recognition
   */
  bool passesAddressCheck(message_t *msg) {
    cc2420_hdr_t *header = (cc2420_hdr_t*)call RadioPacket.getPayload( msg, sizeof(cc2420_hdr_t) );
    int mode = (header->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 3;
//    ieee_eui64_t *ext_addr;  

    if (mode == IEEE154_ADDR_SHORT) {
      return (header->dest == call RadioConfig.getShortAddr()
              || header->dest == IEEE154_BROADCAST_ADDR);
//    } else if (mode == IEEE154_ADDR_EXT) {
//      ieee_eui64_t local_addr = (call RadioConfig.getExtAddr());
//      ext_addr = TCAST(ieee_eui64_t* ONE, &header->dest);
//      return (memcmp(ext_addr->data, local_addr.data, IEEE_EUI64_LENGTH) == 0);
    } else {
      /* reject frames with either no address or invalid type */
      return FALSE;
    }
  }

async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}

}
