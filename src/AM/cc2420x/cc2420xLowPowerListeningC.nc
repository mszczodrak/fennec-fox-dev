configuration cc2420xLowPowerListeningC {
provides interface SplitControl;
provides interface BareSend as Send;
provides interface BareReceive as Receive;
provides interface RadioPacket;
provides interface LowPowerListening;

uses interface SplitControl as SubControl;
uses interface BareSend as SubSend;
uses interface BareReceive as SubReceive;
uses interface RadioPacket as SubPacket;

uses interface LowPowerListeningConfig;
uses interface PacketAcknowledgements;

uses interface cc2420xParams;

}

implementation {

components cc2420xLowPowerListeningP;
cc2420xParams = cc2420xLowPowerListeningP;

LowPowerListening = cc2420xLowPowerListeningP.LowPowerListening;
Send = cc2420xLowPowerListeningP.Send;
Receive = cc2420xLowPowerListeningP.Receive;
SplitControl = cc2420xLowPowerListeningP.SplitControl;
RadioPacket = cc2420xLowPowerListeningP.RadioPacket;

SubSend = cc2420xLowPowerListeningP.SubSend;
SubReceive = cc2420xLowPowerListeningP.SubReceive;
SubControl = cc2420xLowPowerListeningP.SubControl;
SubPacket = cc2420xLowPowerListeningP.SubPacket;

LowPowerListeningConfig = cc2420xLowPowerListeningP.LowPowerListeningConfig;
PacketAcknowledgements = cc2420xLowPowerListeningP.PacketAcknowledgements;

components CC2420XRadioP;
cc2420xLowPowerListeningP.StdControlCC2420XRadioP -> CC2420XRadioP.StdControl;

components cc2420xCollisionLayerC;
cc2420xLowPowerListeningP.StdControlcc2420xCollisionLayerC -> cc2420xCollisionLayerC.StdControl;

/* wire to LowPowerListeningDummyC */
components new LowPowerListeningDummyC();
cc2420xLowPowerListeningP.DummyLowPowerListening -> LowPowerListeningDummyC.LowPowerListening;
cc2420xLowPowerListeningP.DummySend -> LowPowerListeningDummyC.Send;
cc2420xLowPowerListeningP.DummyReceive -> LowPowerListeningDummyC.Receive;
cc2420xLowPowerListeningP.DummySplitControl -> LowPowerListeningDummyC.SplitControl;
cc2420xLowPowerListeningP.DummyRadioPacket -> LowPowerListeningDummyC.RadioPacket;

LowPowerListeningDummyC.SubSend -> cc2420xLowPowerListeningP.DummySubSend;
LowPowerListeningDummyC.SubReceive -> cc2420xLowPowerListeningP.DummySubReceive;
LowPowerListeningDummyC.SubControl -> cc2420xLowPowerListeningP.DummySubControl;
LowPowerListeningDummyC.SubPacket -> cc2420xLowPowerListeningP.DummySubPacket;

/* wire to LowPowerListeningLayerC */
components new LowPowerListeningLayerC();
cc2420xLowPowerListeningP.DefaultLowPowerListening -> LowPowerListeningLayerC.LowPowerListening;
cc2420xLowPowerListeningP.DefaultSend -> LowPowerListeningLayerC.Send;
cc2420xLowPowerListeningP.DefaultReceive -> LowPowerListeningLayerC.Receive;
cc2420xLowPowerListeningP.DefaultSplitControl -> LowPowerListeningLayerC.SplitControl;
cc2420xLowPowerListeningP.DefaultRadioPacket -> LowPowerListeningLayerC.RadioPacket;

LowPowerListeningLayerC.SubSend -> cc2420xLowPowerListeningP.DefaultSubSend;
LowPowerListeningLayerC.SubReceive -> cc2420xLowPowerListeningP.DefaultSubReceive;
LowPowerListeningLayerC.SubControl -> cc2420xLowPowerListeningP.DefaultSubControl;
LowPowerListeningLayerC.SubPacket -> cc2420xLowPowerListeningP.DefaultSubPacket;

LowPowerListeningLayerC.Config -> cc2420xLowPowerListeningP.DefaultLowPowerListeningConfig;
LowPowerListeningLayerC.PacketAcknowledgements -> cc2420xLowPowerListeningP.DefaultPacketAcknowledgements;

}
