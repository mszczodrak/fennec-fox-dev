#include "IEEE802154.h"

configuration cc2420DriverC {
provides interface StdControl;

provides interface RadioBuffer;
provides interface RadioSend;
provides interface RadioPacket;
provides interface RadioCCA;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;

uses interface cc2420RadioParams;
}

implementation {

components cc2420DriverP;
StdControl = cc2420DriverP.StdControl;
RadioCCA = cc2420DriverP.RadioCCA;
cc2420RadioParams = cc2420DriverP.cc2420RadioParams;

RadioBuffer = cc2420DriverP;
RadioSend = cc2420DriverP.RadioSend;
RadioPacket = cc2420DriverP.RadioPacket;

PacketTransmitPower = cc2420DriverP.PacketTransmitPower;
PacketRSSI = cc2420DriverP.PacketRSSI;
PacketTimeSyncOffset = cc2420DriverP.PacketTimeSyncOffset;
PacketLinkQuality = cc2420DriverP.PacketLinkQuality;

RadioLinkPacketMetadata = cc2420DriverP.RadioLinkPacketMetadata;

components MainC;
MainC.SoftwareInit -> cc2420DriverP;

components LedsC;
cc2420DriverP.Leds -> LedsC;

components new Alarm32khz32C() as RAlarm;
cc2420DriverP.RadioTimer -> RAlarm;
  
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

components cc2420ReceiveC;
cc2420DriverP.CC2420Receive -> cc2420ReceiveC;
cc2420DriverP.PacketIndicator -> cc2420ReceiveC.PacketIndicator;
}

