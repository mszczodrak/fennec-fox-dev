generic configuration FFHopCC2420ReceiveC(uint16_t sink, bool speedup_receive) {

  provides interface StdControl;
  provides interface Receive;
  provides interface CC2420Receive;
  provides interface ReceiveIndicator as PacketIndicator;
  uses interface HopCC2420Config;

}

implementation {
  components MainC;
  components new FFHopCC2420ReceiveP(sink, speedup_receive);
  components FFCC2420PacketC;
  components new CC2420SpiC() as Spi;
  
  components HplCC2420PinsC as Pins;
  components HplCC2420InterruptsC as InterruptsC;

  components LedsC as Leds;
  FFHopCC2420ReceiveP.Leds -> Leds;

  StdControl = FFHopCC2420ReceiveP;
  Receive = FFHopCC2420ReceiveP;
  CC2420Receive = FFHopCC2420ReceiveP;
  PacketIndicator = FFHopCC2420ReceiveP.PacketIndicator;
  HopCC2420Config = FFHopCC2420ReceiveP;

  MainC.SoftwareInit -> FFHopCC2420ReceiveP;
  
  FFHopCC2420ReceiveP.CSN -> Pins.CSN;
  FFHopCC2420ReceiveP.FIFO -> Pins.FIFO;
  FFHopCC2420ReceiveP.FIFOP -> Pins.FIFOP;
  FFHopCC2420ReceiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  FFHopCC2420ReceiveP.SpiResource -> Spi;
  FFHopCC2420ReceiveP.RXFIFO -> Spi.RXFIFO;
  FFHopCC2420ReceiveP.SFLUSHRX -> Spi.SFLUSHRX;
  FFHopCC2420ReceiveP.SACK -> Spi.SACK;
  FFHopCC2420ReceiveP.CC2420Packet -> FFCC2420PacketC;
  FFHopCC2420ReceiveP.CC2420PacketBody -> FFCC2420PacketC;
  FFHopCC2420ReceiveP.PacketTimeStamp -> FFCC2420PacketC;

  FFHopCC2420ReceiveP.SECCTRL0 -> Spi.SECCTRL0;
  FFHopCC2420ReceiveP.SECCTRL1 -> Spi.SECCTRL1;
  FFHopCC2420ReceiveP.SRXDEC -> Spi.SRXDEC;
  FFHopCC2420ReceiveP.RXNONCE -> Spi.RXNONCE;
  FFHopCC2420ReceiveP.KEY0 -> Spi.KEY0;
  FFHopCC2420ReceiveP.KEY1 -> Spi.KEY1;
  FFHopCC2420ReceiveP.RXFIFO_RAM -> Spi.RXFIFO_RAM;
  FFHopCC2420ReceiveP.SNOP -> Spi.SNOP;

}
