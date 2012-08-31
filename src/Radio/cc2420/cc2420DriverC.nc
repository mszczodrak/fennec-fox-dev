#include "IEEE802154.h"

configuration cc2420DriverC {
  provides interface StdControl;
  provides interface ReceiveIndicator as EnergyIndicator;
  uses interface cc2420RadioParams;
}

implementation {

  components cc2420DriverP;
  StdControl = cc2420DriverP.StdControl;
  EnergyIndicator = cc2420DriverP.EnergyIndicator;
  cc2420RadioParams = cc2420DriverP.cc2420RadioParams;

  components MainC;
  MainC.SoftwareInit -> cc2420DriverP;
  
  components HplCC2420PinsC as Pins;
  cc2420DriverP.CCA -> Pins.CCA;
  cc2420DriverP.CSN -> Pins.CSN;
  cc2420DriverP.SFD -> Pins.SFD;

  components HplCC2420InterruptsC as Interrupts;
  cc2420DriverP.CaptureSFD -> Interrupts.CaptureSFD;

  components new CC2420SpiC() as Spi;
  cc2420DriverP.SpiResource -> Spi;
  cc2420DriverP.ChipSpiResource -> Spi;
  cc2420DriverP.SNOP        -> Spi.SNOP;
  cc2420DriverP.STXON       -> Spi.STXON;
  cc2420DriverP.STXONCCA    -> Spi.STXONCCA;
  cc2420DriverP.SFLUSHTX    -> Spi.SFLUSHTX;
  cc2420DriverP.TXCTRL      -> Spi.TXCTRL;
  cc2420DriverP.TXFIFO      -> Spi.TXFIFO;
  cc2420DriverP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
  cc2420DriverP.MDMCTRL1    -> Spi.MDMCTRL1;
  cc2420DriverP.SECCTRL0 -> Spi.SECCTRL0;
  cc2420DriverP.SECCTRL1 -> Spi.SECCTRL1;
  cc2420DriverP.STXENC -> Spi.STXENC;
  cc2420DriverP.TXNONCE -> Spi.TXNONCE;
  cc2420DriverP.KEY0 -> Spi.KEY0;
  cc2420DriverP.KEY1 -> Spi.KEY1;
  
}
