generic configuration tinyosRadioC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;
}

implementation {

  components new tinyosRadioP();
  Mgmt = tinyosRadioP;
  Module = tinyosRadioP;
  RadioCall = tinyosRadioP;
  RadioSignal = tinyosRadioP;

  components ActiveMessageC;
  tinyosRadioP.AMControl -> ActiveMessageC;
  tinyosRadioP.Packet -> ActiveMessageC;
  tinyosRadioP.AMPacket -> ActiveMessageC;
  tinyosRadioP.AMSend -> ActiveMessageC.AMSend[101];
  tinyosRadioP.ReceiveReceive -> ActiveMessageC.Receive[101];
  tinyosRadioP.PacketAcknowledgements -> ActiveMessageC.PacketAcknowledgements;

  components new TimerMilliC() as Timer0;
  tinyosRadioP.Timer0 -> Timer0;

}

