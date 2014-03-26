
configuration MultiplexLplC {
provides interface LowPowerListening;
provides interface Send;
provides interface Receive;
provides interface SplitControl;
provides interface State as SendState;

uses interface Send as SubSend;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;

uses interface cc2420Params;
}

implementation {

components MultiplexLplP;
cc2420Params = MultiplexLplP;

LowPowerListening = MultiplexLplP.LowPowerListening;
Send = MultiplexLplP.Send;
Receive = MultiplexLplP.Receive;
SplitControl = MultiplexLplP.SplitControl;
SendState = MultiplexLplP.SendState;

SubSend = MultiplexLplP.SubSend;
SubReceive = MultiplexLplP.SubReceive;
SubControl = MultiplexLplP.SubControl;

/* wire to DummyLplC */
components DummyLplC;
MultiplexLplP.DummyLowPowerListening -> DummyLplC.LowPowerListening;
MultiplexLplP.DummySend -> DummyLplC.Send;
MultiplexLplP.DummyReceive -> DummyLplC.Receive;
MultiplexLplP.DummySplitControl -> DummyLplC.SplitControl;
MultiplexLplP.DummySendState -> DummyLplC.SendState;

DummyLplC.SubSend -> MultiplexLplP.DummySubSend;
DummyLplC.SubReceive -> MultiplexLplP.DummySubReceive;
DummyLplC.SubControl -> MultiplexLplP.DummySubControl;

/* wire to DefaultLplC */
components DefaultLplC;
MultiplexLplP.DefaultLowPowerListening -> DefaultLplC.LowPowerListening;
MultiplexLplP.DefaultSend -> DefaultLplC.Send;
MultiplexLplP.DefaultReceive -> DefaultLplC.Receive;
MultiplexLplP.DefaultSplitControl -> DefaultLplC.SplitControl;
MultiplexLplP.DefaultSendState -> DefaultLplC.SendState;

DefaultLplC.SubSend -> MultiplexLplP.DefaultSubSend;
DefaultLplC.SubReceive -> MultiplexLplP.DefaultSubReceive;
DefaultLplC.SubControl -> MultiplexLplP.DefaultSubControl;

}
