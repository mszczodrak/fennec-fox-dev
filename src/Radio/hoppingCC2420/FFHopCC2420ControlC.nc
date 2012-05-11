
#include "FFCC2420.h"
#include "IEEE802154.h"

generic configuration FFHopCC2420ControlC(uint8_t number_of_channels,
                                                uint16_t channel_lifetime,
                                                bool speedup_receive,
						bool use_ack) {


  provides interface Resource;
  provides interface HopCC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;
  
}

implementation {
  
  components new FFHopCC2420ControlP(number_of_channels, channel_lifetime, speedup_receive, use_ack);
  Resource = FFHopCC2420ControlP;
  HopCC2420Config = FFHopCC2420ControlP;
  CC2420Power = FFHopCC2420ControlP;
  ReadRssi = FFHopCC2420ControlP;

  components MainC;
  MainC.SoftwareInit -> FFHopCC2420ControlP;
  
  components AlarmMultiplexC as Alarm;
  FFHopCC2420ControlP.StartupTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  FFHopCC2420ControlP.CSN -> Pins.CSN;
  FFHopCC2420ControlP.RSTN -> Pins.RSTN;
  FFHopCC2420ControlP.VREN -> Pins.VREN;

  components HplCC2420InterruptsC as Interrupts;
  FFHopCC2420ControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2420SpiC() as Spi;
  FFHopCC2420ControlP.SpiResource -> Spi;
  FFHopCC2420ControlP.SRXON -> Spi.SRXON;
  FFHopCC2420ControlP.SRFOFF -> Spi.SRFOFF;
  FFHopCC2420ControlP.SXOSCON -> Spi.SXOSCON;
  FFHopCC2420ControlP.SXOSCOFF -> Spi.SXOSCOFF;
  FFHopCC2420ControlP.FSCTRL -> Spi.FSCTRL;
  FFHopCC2420ControlP.IOCFG0 -> Spi.IOCFG0;
  FFHopCC2420ControlP.IOCFG1 -> Spi.IOCFG1;
  FFHopCC2420ControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  FFHopCC2420ControlP.MDMCTRL1 -> Spi.MDMCTRL1;
  FFHopCC2420ControlP.PANID -> Spi.PANID;
  FFHopCC2420ControlP.IEEEADR -> Spi.IEEEADR;
  FFHopCC2420ControlP.RXCTRL1 -> Spi.RXCTRL1;
  FFHopCC2420ControlP.RSSI  -> Spi.RSSI;
  FFHopCC2420ControlP.TXCTRL  -> Spi.TXCTRL;

  components new CC2420SpiC() as SyncSpiC;
  FFHopCC2420ControlP.SyncResource -> SyncSpiC;

  components new CC2420SpiC() as RssiResource;
  FFHopCC2420ControlP.RssiResource -> RssiResource;
  
  components ActiveMessageAddressC;
  FFHopCC2420ControlP.ActiveMessageAddress -> ActiveMessageAddressC;

  components LocalIeeeEui64C;
  FFHopCC2420ControlP.LocalIeeeEui64 -> LocalIeeeEui64C;

  components new TimerMilliC() as ChannelTimeout;
  FFHopCC2420ControlP.ChannelTimeout -> ChannelTimeout;
}

