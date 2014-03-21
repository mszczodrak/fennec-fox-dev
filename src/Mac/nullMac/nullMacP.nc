#include <Fennec.h>

generic module nullMacP(process_t process) {
uses interface nullMacParams;
uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface SlottedCollisionConfig;
uses interface LowPowerListeningConfig;
uses interface DummyConfig;
uses interface LocalTime<TRadio> as LocalTimeRadio;

uses interface RadioReceive;
uses interface RadioCCA;
uses interface RadioState;
uses interface RadioPacket;
uses interface RadioSend;
uses interface PacketFlag as AckReceivedFlag;

provides interface PacketAcknowledgements;
provides interface BareSend;
provides interface BareReceive;

}

implementation {

message_t *m;

command error_t BareSend.send(message_t* msg) {
	m = msg;
	return call RadioSend.send(msg);
}

command error_t BareSend.cancel(message_t* msg) {
}





tasklet_async event void RadioCCA.done(error_t error) {

}

tasklet_async event void RadioState.done() {

}

tasklet_async event void RadioSend.ready() {

}

tasklet_async event void RadioSend.sendDone(error_t error) {
	signal BareSend.sendDone(m, error);
}


async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
	return SUCCESS;
}

async command error_t PacketAcknowledgements.noAck(message_t* msg) {
	return SUCCESS;
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return SUCCESS;
}

tasklet_async event message_t* RadioReceive.receive(message_t* msg) {
	return signal BareReceive.receive(msg);
}

tasklet_async event bool RadioReceive.header(message_t* msg) {
	return TRUE;
}

}
