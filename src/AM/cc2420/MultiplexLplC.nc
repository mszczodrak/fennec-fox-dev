
configuration MultiplexLplC {
provides interface LowPowerListening;
provides interface Send;
provides interface Receive;
provides interface SplitControl;
provides interface State as SendState;

uses interface Send as SubSend;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;

}

implementation {


components MultiplexLplP;

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








}
