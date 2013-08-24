configuration FennecPacketC {

provides {
//    interface FennecPacket;
//    interface PacketAcknowledgements as Acks;
//    interface FennecPacketBody;
//    interface LinkPacketMetadata;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
}

}

implementation {
  components FennecPacketP;
  PacketTimeStamp32khz = FennecPacketP;
  PacketTimeStampMilli = FennecPacketP;
  PacketTimeSyncOffset = FennecPacketP;

#ifndef TOSSIM
  components Counter32khz32C, new CounterToLocalTimeC(T32khz);
  CounterToLocalTimeC.Counter -> Counter32khz32C;
  FennecPacketP.LocalTime32khz -> CounterToLocalTimeC;

  //DummyTimer is introduced to compile apps that use no timers
  components HilTimerMilliC, new TimerMilliC() as DummyTimer;
  FennecPacketP.LocalTimeMilli -> HilTimerMilliC;
#endif

}
