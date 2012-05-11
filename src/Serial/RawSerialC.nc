configuration RawSerialC {
  provides interface Serial;	
//  provides interface StdControl;
}

implementation
{
  components RawSerialP;
  Serial = RawSerialP;
//  StdControl = RawSerialP;

  components PlatformSerialC;
  RawSerialP.UartByte -> PlatformSerialC;
  RawSerialP.UartControl -> PlatformSerialC;
}
