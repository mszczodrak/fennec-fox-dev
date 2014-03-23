#include <Fennec.h>

generic module nullMacP(process_t process) {
uses interface nullMacParams;
uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface SlottedCollisionConfig;
uses interface RandomCollisionConfig;
uses interface LowPowerListeningConfig;
uses interface DummyConfig;
uses interface UniqueConfig;
uses interface SoftwareAckConfig;
uses interface LocalTime<TRadio> as LocalTimeRadio;

uses interface RadioReceive;
uses interface RadioCCA;
uses interface RadioState;
uses interface RadioSend;
uses interface PacketFlag as AckReceivedFlag;

uses interface RadioAlarm;

provides interface SplitControl;
provides interface PacketAcknowledgements;
provides interface BareSend;
provides interface BareReceive;

provides interface LowPowerListening;
provides interface RadioChannel;

}

implementation {

norace message_t *m;
norace error_t e;

command error_t SplitControl.start() {
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t BareSend.send(message_t* msg) {
	m = msg;
	return call RadioSend.send(msg);
}

command error_t BareSend.cancel(message_t* msg) {
}

command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) { }

command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) { 
	return 0; 
}

command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) { }

command uint16_t LowPowerListening.getLocalWakeupInterval() { return 0; }

tasklet_async event void RadioCCA.done(error_t error) {

}

tasklet_async event void RadioState.done() {

}

tasklet_async event void RadioSend.ready() {

}

task void sendDone() {
	signal BareSend.sendDone(m, e);
}

tasklet_async event void RadioSend.sendDone(error_t error) {
	e = error;	
}

command error_t RadioChannel.setChannel(uint8_t channel) {
	return SUCCESS;
}

command uint8_t RadioChannel.getChannel() {
	return 26;
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

tasklet_async event void RadioAlarm.fired() {
}

}
