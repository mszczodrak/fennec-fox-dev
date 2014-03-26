
configuration CC2420MultiplexLplC {
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

components CC2420MultiplexLplP;
cc2420Params = CC2420MultiplexLplP;

LowPowerListening = CC2420MultiplexLplP.LowPowerListening;
Send = CC2420MultiplexLplP.Send;
Receive = CC2420MultiplexLplP.Receive;
SplitControl = CC2420MultiplexLplP.SplitControl;
SendState = CC2420MultiplexLplP.SendState;

SubSend = CC2420MultiplexLplP.SubSend;
SubReceive = CC2420MultiplexLplP.SubReceive;
SubControl = CC2420MultiplexLplP.SubControl;

/* wire to DummyLplC */
components DummyLplC;
CC2420MultiplexLplP.DummyLowPowerListening -> DummyLplC.LowPowerListening;
CC2420MultiplexLplP.DummySend -> DummyLplC.Send;
CC2420MultiplexLplP.DummyReceive -> DummyLplC.Receive;
CC2420MultiplexLplP.DummySplitControl -> DummyLplC.SplitControl;
CC2420MultiplexLplP.DummySendState -> DummyLplC.SendState;

DummyLplC.SubSend -> CC2420MultiplexLplP.DummySubSend;
DummyLplC.SubReceive -> CC2420MultiplexLplP.DummySubReceive;
DummyLplC.SubControl -> CC2420MultiplexLplP.DummySubControl;

/* wire to DefaultLplC */
components DefaultLplC;
CC2420MultiplexLplP.DefaultLowPowerListening -> DefaultLplC.LowPowerListening;
CC2420MultiplexLplP.DefaultSend -> DefaultLplC.Send;
CC2420MultiplexLplP.DefaultReceive -> DefaultLplC.Receive;
CC2420MultiplexLplP.DefaultSplitControl -> DefaultLplC.SplitControl;
CC2420MultiplexLplP.DefaultSendState -> DefaultLplC.SendState;

DefaultLplC.SubSend -> CC2420MultiplexLplP.DefaultSubSend;
DefaultLplC.SubReceive -> CC2420MultiplexLplP.DefaultSubReceive;
DefaultLplC.SubControl -> CC2420MultiplexLplP.DefaultSubControl;

}
