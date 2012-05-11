configuration SerialCommC {
  provides interface Serial;	
  provides interface StdControl;
}

implementation
{
  components SerialCommP;
  Serial = SerialCommP;
  StdControl = SerialCommP;

  components SerialActiveMessageC as SA;
  SerialCommP.SerialControl -> SA;
  SerialCommP.Packet -> SA;
  SerialCommP.FrameSend -> SA.AMSend[AM_BIGMSG_FRAME_PART];
  SerialCommP.Receive  -> SA.Receive[AM_BIGMSG_FRAME_REQUEST];
}
