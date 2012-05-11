#include "IEEE802154.h"

generic configuration FFHopCC2420TransmitC() {

  provides {
    interface StdControl;
    interface CC2420Transmit;
    interface ReceiveIndicator as EnergyIndicator;
    interface ReceiveIndicator as ByteIndicator;
  }

  uses interface CC2420Receive;
  uses interface HopCC2420Config;
}

implementation {

  components new FFHopCC2420TransmitP();
  StdControl = FFHopCC2420TransmitP;
  CC2420Transmit = FFHopCC2420TransmitP;
  CC2420Receive = FFHopCC2420TransmitP;
  HopCC2420Config = FFHopCC2420TransmitP;
  EnergyIndicator = FFHopCC2420TransmitP.EnergyIndicator;
  ByteIndicator = FFHopCC2420TransmitP.ByteIndicator;

  components MainC;
  MainC.SoftwareInit -> FFHopCC2420TransmitP;
  MainC.SoftwareInit -> Alarm;
  
  components AlarmMultiplexC as Alarm;
  FFHopCC2420TransmitP.BackoffTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  FFHopCC2420TransmitP.CCA -> Pins.CCA;
  FFHopCC2420TransmitP.CSN -> Pins.CSN;
  FFHopCC2420TransmitP.SFD -> Pins.SFD;

  components HplCC2420InterruptsC as Interrupts;
  FFHopCC2420TransmitP.CaptureSFD -> Interrupts.CaptureSFD;

  components new CC2420SpiC() as Spi;
  FFHopCC2420TransmitP.SpiResource -> Spi;
  FFHopCC2420TransmitP.ChipSpiResource -> Spi;
  FFHopCC2420TransmitP.SNOP        -> Spi.SNOP;
  FFHopCC2420TransmitP.STXON       -> Spi.STXON;
  FFHopCC2420TransmitP.STXONCCA    -> Spi.STXONCCA;
  FFHopCC2420TransmitP.SFLUSHTX    -> Spi.SFLUSHTX;
  FFHopCC2420TransmitP.TXCTRL      -> Spi.TXCTRL;
  FFHopCC2420TransmitP.TXFIFO      -> Spi.TXFIFO;
  FFHopCC2420TransmitP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
  FFHopCC2420TransmitP.MDMCTRL1    -> Spi.MDMCTRL1;
  FFHopCC2420TransmitP.SECCTRL0 -> Spi.SECCTRL0;
  FFHopCC2420TransmitP.SECCTRL1 -> Spi.SECCTRL1;
  FFHopCC2420TransmitP.STXENC -> Spi.STXENC;
  FFHopCC2420TransmitP.TXNONCE -> Spi.TXNONCE;
  FFHopCC2420TransmitP.KEY0 -> Spi.KEY0;
  FFHopCC2420TransmitP.KEY1 -> Spi.KEY1;
  
  components FFCC2420PacketC;
  FFHopCC2420TransmitP.CC2420Packet -> FFCC2420PacketC;
  FFHopCC2420TransmitP.CC2420PacketBody -> FFCC2420PacketC;
  FFHopCC2420TransmitP.PacketTimeStamp -> FFCC2420PacketC;
  FFHopCC2420TransmitP.PacketTimeSyncOffset -> FFCC2420PacketC;

  components LedsC;
  FFHopCC2420TransmitP.Leds -> LedsC;

}
