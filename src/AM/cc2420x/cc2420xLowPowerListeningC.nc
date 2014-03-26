generic configuration cc2420xLowPowerListeningC() {
provides interface SplitControl;
provides interface BareSend as Send;
provides interface BareReceive as Receive;
provides interface RadioPacket;
provides interface LowPowerListening;

uses interface SplitControl as SubControl;
uses interface BareSend as SubSend;
uses interface BareReceive as SubReceive;
uses interface RadioPacket as SubPacket;

uses interface LowPowerListeningConfig as Config;
uses interface PacketAcknowledgements;

uses interface cc2420xParams;

}

implementation {

components new cc2420xLowPowerListeningP();
cc2420xParams = cc2420xLowPowerListeningP;

LowPowerListening = cc2420xLowPowerListeningP.LowPowerListening;
Send = cc2420xLowPowerListeningP.Send;
Receive = cc2420xLowPowerListeningP.Receive;
SplitControl = cc2420xLowPowerListeningP.SplitControl;
RadioPacket = cc2420xLowPowerListeningP.RadioPacket;

SubSend = cc2420xLowPowerListeningP.SubSend;
SubReceive = cc2420xLowPowerListeningP.SubReceive;
SubControl = cc2420xLowPowerListeningP.SubControl;

LowPowerListeningConfig = cc2420xLowPowerListeningP.LowPowerListeningConfig;
PacketAcknowledgements = cc2420xLowPowerListeningP.PacketAcknowledgements;

/* wire to DummyLplC */
components new LowPowerListeningDummyC() as DummyLplC;
cc2420xLowPowerListeningP.DummyLowPowerListening -> DummyLplC.LowPowerListening;
cc2420xLowPowerListeningP.DummySend -> DummyLplC.Send;
cc2420xLowPowerListeningP.DummyReceive -> DummyLplC.Receive;
cc2420xLowPowerListeningP.DummySplitControl -> DummyLplC.SplitControl;
cc2420xLowPowerListeningP.DummyRadioPacket -> DummyLplC.RadioPacket;

DummyLplC.SubSend -> cc2420xLowPowerListeningP.DummySubSend;
DummyLplC.SubReceive -> cc2420xLowPowerListeningP.DummySubReceive;
DummyLplC.SubControl -> cc2420xLowPowerListeningP.DummySubControl;

/* wire to DefaultLplC */
components new LowPowerListeningLayerC() as DefaultLplC;
cc2420xLowPowerListeningP.DefaultLowPowerListening -> DefaultLplC.LowPowerListening;
cc2420xLowPowerListeningP.DefaultSend -> DefaultLplC.Send;
cc2420xLowPowerListeningP.DefaultReceive -> DefaultLplC.Receive;
cc2420xLowPowerListeningP.DefaultSplitControl -> DefaultLplC.SplitControl;
cc2420xLowPowerListeningP.DefaultRadioPacket -> DefaultLplC.RadioPacket;

DefaultLplC.SubSend -> cc2420xLowPowerListeningP.DefaultSubSend;
DefaultLplC.SubReceive -> cc2420xLowPowerListeningP.DefaultSubReceive;
DefaultLplC.SubControl -> cc2420xLowPowerListeningP.DefaultSubControl;

}
