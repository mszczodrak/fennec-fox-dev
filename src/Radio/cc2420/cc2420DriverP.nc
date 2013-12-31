#include "CC2420TimeSyncMessage.h"
#include "crc.h"
#include "message.h"
#include "Fennec.h"

module cc2420DriverP @safe() {

provides interface Init;
provides interface StdControl;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;
 
uses interface Leds; 
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
uses interface cc2420RadioParams;
provides interface RadioSend;
provides interface RadioBuffer;
provides interface RadioPacket;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;
uses interface Alarm<T32khz,uint32_t> as RadioTimer;

}

implementation {

norace message_t * ONE_NOK radio_msg;
norace bool radio_cca = FALSE;
norace uint8_t radio_state = S_STOPPED;
norace uint8_t failed_load_counter = 0;
norace error_t errorSendDone;


/** Byte reception/transmission indicator */
bool sfdHigh;

norace bool m_receiving = FALSE;

norace uint8_t m_tx_power;
uint16_t m_prev_time;
norace uint16_t param_tx_power;

/** Let the CC2420 driver keep a lock on the SPI while waiting for an ack */
norace bool abortSpiRelease;

// This specifies how many jiffies the stack should wait after a
// TXACTIVE to receive an SFD interrupt before assuming something is
// wrong and aborting the send. There seems to be a condition
// on the micaZ where the SFD interrupt is never handled.
enum {
	CC2420_ABORT_PERIOD = 320
};


void low_level_init() {
	call CCA.makeInput();
	call CSN.makeOutput();
	call SFD.makeInput();
}


command error_t StdControl.start() {
	radio_state = S_STARTED;
	m_tx_power = 0;
	m_receiving = FALSE;
	failed_load_counter = 0;
	param_tx_power = call cc2420RadioParams.get_power();
	call CaptureSFD.captureRisingEdge();
	abortSpiRelease = FALSE;
	return SUCCESS;
}

command error_t StdControl.stop() {
	radio_state = S_STOPPED;
	call RadioTimer.stop();
	call CaptureSFD.disable();
	call SpiResource.release();  // REMOVE
	call CSN.set();
	return SUCCESS;
}

/***************** Init Commands *****************/
command error_t Init.init() {
	low_level_init();
	return SUCCESS;
}

async command bool EnergyIndicator.isReceiving() {
	return !(call CCA.get());
}
  

error_t releaseSpiResource() {
	call SpiResource.release();
	return SUCCESS;
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

task void updateTXPower() {
	param_tx_power = call cc2420RadioParams.get_power();
} 

task void radioSendDone() {
	signal RadioSend.sendDone(radio_msg, errorSendDone);
}

void signalDone( error_t err ) {
	errorSendDone = err;
	post radioSendDone();
	atomic {
		radio_state = S_STARTED;
		abortSpiRelease = FALSE;
		failed_load_counter = 0;
		call ChipSpiResource.attemptRelease();
	}
}


// this method converts a 16-bit timestamp into a 32-bit one
inline uint32_t getTime32(uint16_t captured_time) {
	uint32_t now = call RadioTimer.getNow();

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

	call CSN.clr();
	status = radio_cca ? call STXONCCA.strobe() : call STXON.strobe();
	if ( !( status & CC2420_STATUS_TX_ACTIVE ) ) {
		status = call SNOP.strobe();
		if ( status & CC2420_STATUS_TX_ACTIVE ) {
			congestion = FALSE;
		}
	}

	call CSN.set();

	if ( congestion ) {
		signal RadioSend.sendDone(radio_msg, EBUSY);
		releaseSpiResource();
	} else {
		radio_state = S_SFD;
		call RadioTimer.start(CC2420_ABORT_PERIOD);
	}
}


async command bool ByteIndicator.isReceiving() {
	bool high;
	high = sfdHigh;
	return high;
}

async event void CC2420Receive.receive( uint8_t type, message_t* ack_msg ) {
	cc2420_hdr_t* ack_header;
	cc2420_hdr_t* msg_header;
	metadata_t* msg_metadata;
	uint8_t* ack_buf;
	uint8_t length;

	if ( type == IEEE154_TYPE_ACK && radio_msg) {
		ack_header = (cc2420_hdr_t*) (ack_msg->data);
		msg_header = (cc2420_hdr_t*) (radio_msg->data);

		if ( radio_state == S_ACK_WAIT && msg_header->dsn == ack_header->dsn ) {
			call RadioTimer.stop();

			msg_metadata = (metadata_t*)getMetadata( radio_msg );
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
async event void CaptureSFD.captured( uint16_t rtime ) {
	uint32_t time32;
	uint8_t sfd_state = 0;
	cc2420_hdr_t* header = (cc2420_hdr_t*) ( radio_msg->data );

	atomic {
		time32 = getTime32(rtime);
		switch( radio_state ) {

		case S_SFD:
			radio_state = S_EFD;
			sfdHigh = TRUE;
			// in case we got stuck in the receive SFD interrupts, we can reset
			// the state here since we know that we are not receiving anymore
			m_receiving = FALSE;
			call CaptureSFD.captureFallingEdge();
			call PacketTimeSyncOffset.set(radio_msg, time32);
			if (call PacketTimeSyncOffset.isSet(radio_msg)) {
			//uint8_t absOffset = sizeof(message_header_t)-sizeof(cc2420_hdr_t) + call PacketTimeSyncOffset.get(radio_msg);
				uint8_t absOffset = call PacketTimeSyncOffset.get(radio_msg);
				timesync_radio_t *timesync = (timesync_radio_t *)((nx_uint8_t*)radio_msg+absOffset);
				// set timesync event time as the offset between the 
				// event time and the SFD interrupt time (TEP  133)
				*timesync  -= time32;
				call CSN.clr();
				call TXFIFO_RAM.write( absOffset, (uint8_t*)timesync, sizeof(timesync_radio_t) );
				call CSN.set();
				//restoring the event time to the original value
				*timesync  += time32;
			}

			if ( header->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
				// This is an ack packet, dont release the chips SPI bus lock.
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

			if ( header->fcf & ( 1 << IEEE154_FCF_ACK_REQ ) ) {
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
				m_prev_time = rtime;
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
				if ((sfd_state == 0) && (rtime - m_prev_time < 10) ) {
					call CC2420Receive.sfd_dropped();
					if (radio_msg)
						call PacketTimeSyncOffset.clear(radio_msg);
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
	cc2420_hdr_t* header = (cc2420_hdr_t*) ( radio_msg->data );
	metadata_t* meta = (metadata_t*) getMetadata( radio_msg );
	uint8_t tx_power = meta->tx_power;

	if ( !tx_power ) {
		tx_power = param_tx_power;
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


async command error_t RadioBuffer.load(message_t* msg) {
	if (radio_state != S_STARTED) {
		failed_load_counter++;
		if (failed_load_counter > CC2420_MAX_FAILED_LOADS) {
			signalDone(FAIL);
		}
		return FAIL;
	}
	atomic {
		radio_state = S_LOAD;
		radio_msg = msg;
	}
	post updateTXPower();
	if ( acquireSpiResource() == SUCCESS ) {
		loadTXFIFO();
	}
	return SUCCESS;
}


async command error_t RadioSend.send(message_t* msg, bool useCca) {
	if (msg != radio_msg)
		return FAIL;
	if (radio_state != S_LOAD) {
	}

	radio_cca = useCca;
	radio_state = S_BEGIN_TRANSMIT;

	if ( acquireSpiResource() == SUCCESS ) {
		attemptSend();
	}
	return SUCCESS;
}

/*
async command error_t RadioSend.cancel(message_t *msg) {
	call CSN.clr();
	call SFLUSHTX.strobe();
	call CSN.set();
	releaseSpiResource();
	radio_state = S_STARTED;
	return SUCCESS;
}
*/

/* Radio Packet */

async command uint8_t RadioPacket.maxPayloadLength() {
	return CC2420_MAX_MESSAGE_SIZE - sizeof(nx_struct cc2420_radio_header_t) - CC2420_SIZEOF_CRC - sizeof(timesync_radio_t);
}


async command uint8_t RadioPacket.headerLength(message_t* msg) {
	return sizeof(nx_struct cc2420_radio_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	nx_struct cc2420_radio_header_t *hdr = (nx_struct cc2420_radio_header_t*)(msg->data); 
	return hdr->length - sizeof(nx_struct cc2420_radio_header_t) - CC2420_SIZEOF_CRC - sizeof(timesync_radio_t);
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	nx_struct cc2420_radio_header_t *hdr = (nx_struct cc2420_radio_header_t*)(msg->data); 
	hdr->length = length + sizeof(nx_struct cc2420_radio_header_t) + CC2420_SIZEOF_CRC + sizeof(timesync_radio_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
	return sizeof(metadata_t);
}

async command void RadioPacket.clear(message_t* msg) {
        memset(msg, 0x0, sizeof(message_t));
}



/***************** SpiResource Events ****************/
event void SpiResource.granted() {
	uint8_t cur_state;

	cur_state = radio_state;

	switch( cur_state ) {
	case S_LOAD:
		loadTXFIFO();
		break;

	case S_BEGIN_TRANSMIT:
		attemptSend();
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
	signal RadioBuffer.loadDone(radio_msg, error);
}

async event void TXFIFO.readDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
}


async command bool RadioLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return call PacketLinkQuality.get(msg) > 105;
}

async command error_t RadioCCA.request() {
	switch (radio_state) {
	case S_STOPPED:
		signal RadioCCA.done(FAIL);
		return FAIL;

	default:
		if (call CCA.get()) {
			signal RadioCCA.done(SUCCESS);
		} else {
			signal RadioCCA.done(EBUSY);
		}
	}
	return SUCCESS;
}


async command bool PacketTransmitPower.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<1);
}

async command uint8_t PacketTransmitPower.get(message_t* msg) {
	return getMetadata(msg)->tx_power;
}

async command void PacketTransmitPower.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<1);
}

async command void PacketTransmitPower.set(message_t* msg, uint8_t value) {
	getMetadata(msg)->flags |= (1<<1);
	getMetadata(msg)->tx_power = value;
}


async command bool PacketRSSI.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<2);
}

async command uint8_t PacketRSSI.get(message_t* msg) {
	return getMetadata(msg)->rssi;
}

async command void PacketRSSI.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<2);
}

async command void PacketRSSI.set(message_t* msg, uint8_t value) {
	call PacketTransmitPower.clear(msg);
	getMetadata(msg)->flags |= (1<<2);
	getMetadata(msg)->rssi = value;
}


async command bool PacketTimeSyncOffset.isSet(message_t* msg) {
	return getMetadata(msg)->flags & (1<<3);
}

async command uint8_t PacketTimeSyncOffset.get(message_t* msg) {
	// TODO: 
	//return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
	return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg);
}

async command void PacketTimeSyncOffset.clear(message_t* msg) {
	getMetadata(msg)->flags &= ~(1<<3);
}

async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value) {
	getMetadata(msg)->flags |= (1<<3);
	// we do not store the value, the time sync field is always the last 4 bytes
}

async command bool PacketLinkQuality.isSet(message_t* msg) {
	return TRUE;
}

async command uint8_t PacketLinkQuality.get(message_t* msg) {
	return getMetadata(msg)->lqi;
}

async command void PacketLinkQuality.clear(message_t* msg){
}

async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
	getMetadata(msg)->lqi = value;
}






}

