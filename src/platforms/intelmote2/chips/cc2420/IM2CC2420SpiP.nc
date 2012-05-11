configuration IM2CC2420SpiP 
{
  
  provides interface Init;
  provides interface Resource[uint8_t id];
  provides interface SpiByte;
  provides interface SpiPacket[uint8_t instance];

}

implementation 
{

  components new SimpleFcfsArbiterC("CC2420SpiClient") as FcfsArbiterC;
//
#ifdef PXA_WITH_DMA
  components new HalPXA27xSpiDMAC(1,0x7,FALSE) as HalPXA27xSpiM; // 6.5 Mbps, 8bit width
#else
  components new HalPXA27xSpiPioC(1,0x7,FALSE) as HalPXA27xSpiM; // 6.5 Mbps, 8bit width
#endif
  components IM2CC2420InitSpiP;
  components HplPXA27xSSP3C;
  components HplPXA27xDMAC;
  components HplPXA27xGPIOC;
  components PlatformP;

  Init = IM2CC2420InitSpiP;
  Init = HalPXA27xSpiM.Init;

  SpiByte = HalPXA27xSpiM;
  SpiPacket = HalPXA27xSpiM;
  Resource = FcfsArbiterC;

  IM2CC2420InitSpiP.SCLK -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_SCLK];
  IM2CC2420InitSpiP.TXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_TXD];
  IM2CC2420InitSpiP.RXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_RXD];

#ifdef PXA_WITH_DMA
  HalPXA27xSpiM.RxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[0];
  HalPXA27xSpiM.TxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[1];
  HalPXA27xSpiM.SSPRxDMAInfo -> HplPXA27xSSP3C.SSPRxDMAInfo;
  HalPXA27xSpiM.SSPTxDMAInfo -> HplPXA27xSSP3C.SSPTxDMAInfo;
#endif

  HalPXA27xSpiM.SSP -> HplPXA27xSSP3C.HplPXA27xSSP;
  
}
