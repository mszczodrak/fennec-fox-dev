#include <Fennec.h>
#include "down_sample.h"

generic module down_sampleP(process_t process_id) {
provides interface SplitControl;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;
}

implementation {

uint16_t input;
uint16_t output;
uint16_t scale;

uint32_t event_counter = 0;

command error_t SplitControl.start() {
	call Param.get(INPUT, &input, sizeof(input));
	call Param.get(OUTPUT, &output, sizeof(output));
	call Param.get(SCALE, &scale, sizeof(scale));
	event_counter = 0;

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application down_sample start()\n", process);
#else
	//call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application down_sample stop()\n", process);
#else
	//call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id, bool conflict) {
        switch(var_id) {
        case INPUT:
                event_counter++;
		if (event_counter % scale == 0) {
			output = event_counter / scale;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
        		printf("[%u] Application down_sample output %u\n", process, output);
#else
	        	call SerialDbgs.dbgs(DBGS_SEND_DATA, 0, 0, 0);
#endif
#endif
			call Param.set(OUTPUT, &output, sizeof(output));
		}
                break;
        default:
                break;
        }

}

}
