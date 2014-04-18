/*
 * Application: 
 * Author: 
 * Date: 
 */

generic configuration SendPictureAppC(uint16_t src, uint16_t dest, uint16_t pic_delay) {
  provides interface Mgmt;
  provides interface Module;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {

#ifdef PXA27X_HARDWARE_H

  components new SendPictureAppP(src, dest, pic_delay);
  Mgmt = SendPictureAppP;
  Module = SendPictureAppP;

  NetworkAMSend = SendPictureAppP.NetworkAMSend;
  NetworkReceive = SendPictureAppP.NetworkReceive;
  NetworkSnoop = SendPictureAppP.NetworkSnoop;
  NetworkAMPacket = SendPictureAppP.NetworkAMPacket;
  NetworkPacket = SendPictureAppP.NetworkPacket;
  NetworkPacketAcknowledgements = SendPictureAppP.NetworkPacketAcknowledgements;
  NetworkStatus = SendPictureAppP.NetworkStatus;

  components LedsC;
  SendPictureAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  SendPictureAppP.Timer0 -> Timer0;

  components new TimerMilliC() as Timer1;
  SendPictureAppP.Timer1 -> Timer1;

  components CameraC;
  SendPictureAppP.Camera -> CameraC;

  components RawSerialC;
  SendPictureAppP.Serial -> RawSerialC;

#else

  components new dummyAppC();

  Mgmt = dummyAppC;
  Module = dummyAppC;
  NetworkAMSend = dummyAppC;
  NetworkReceive = dummyAppC.NetworkReceive;
  NetworkSnoop = dummyAppC.NetworkSnoop;
  NetworkAMPacket = dummyAppC.NetworkAMPacket;
  NetworkPacket = dummyAppC.NetworkPacket;
  NetworkPacketAcknowledgements = dummyAppC.NetworkPacketAcknowledgements;
  NetworkStatus = dummyAppC.NetworkStatus;

#endif
}
