/* Swift Fox generated code for Fennec Fox Application configuration */

#include <Fennec.h>

configuration FennecEngineC {
  provides interface Mgmt;
}

implementation {

  components FennecEngineP;
  Mgmt = FennecEngineP.Mgmt;
  components new TimerMilliC() as Timer;
  FennecEngineP.Timer -> Timer;

  /* Defined and linked applications */

  components ControlUnitAppC as ControlUnitApp;
  components ControlUnitAppParamsC;
  ControlUnitApp.ControlUnitAppParams -> ControlUnitAppParamsC;
  FennecEngineP.ControlUnitAppControl -> ControlUnitApp;
  FennecEngineP.ControlUnitAppNetworkAMSend <- ControlUnitApp.NetworkAMSend;
  FennecEngineP.ControlUnitAppNetworkReceive <- ControlUnitApp.NetworkReceive;
  FennecEngineP.ControlUnitAppNetworkSnoop <- ControlUnitApp.NetworkSnoop;
  FennecEngineP.ControlUnitAppNetworkPacket <- ControlUnitApp.NetworkPacket;
  FennecEngineP.ControlUnitAppNetworkAMPacket <- ControlUnitApp.NetworkAMPacket;
  FennecEngineP.ControlUnitAppNetworkPacketAcknowledgements <- ControlUnitApp.NetworkPacketAcknowledgements;
  FennecEngineP.ControlUnitAppNetworkStatus <- ControlUnitApp.NetworkStatus;

  components BlinkAppC as BlinkApp;
  components BlinkAppParamsC;
  BlinkApp.BlinkAppParams -> BlinkAppParamsC;
  FennecEngineP.BlinkAppControl -> BlinkApp;
  FennecEngineP.BlinkAppNetworkAMSend <- BlinkApp.NetworkAMSend;
  FennecEngineP.BlinkAppNetworkReceive <- BlinkApp.NetworkReceive;
  FennecEngineP.BlinkAppNetworkSnoop <- BlinkApp.NetworkSnoop;
  FennecEngineP.BlinkAppNetworkPacket <- BlinkApp.NetworkPacket;
  FennecEngineP.BlinkAppNetworkAMPacket <- BlinkApp.NetworkAMPacket;
  FennecEngineP.BlinkAppNetworkPacketAcknowledgements <- BlinkApp.NetworkPacketAcknowledgements;
  FennecEngineP.BlinkAppNetworkStatus <- BlinkApp.NetworkStatus;

  components nullAppC as nullApp;
  components nullAppParamsC;
  nullApp.nullAppParams -> nullAppParamsC;
  FennecEngineP.nullAppControl -> nullApp;
  FennecEngineP.nullAppNetworkAMSend <- nullApp.NetworkAMSend;
  FennecEngineP.nullAppNetworkReceive <- nullApp.NetworkReceive;
  FennecEngineP.nullAppNetworkSnoop <- nullApp.NetworkSnoop;
  FennecEngineP.nullAppNetworkPacket <- nullApp.NetworkPacket;
  FennecEngineP.nullAppNetworkAMPacket <- nullApp.NetworkAMPacket;
  FennecEngineP.nullAppNetworkPacketAcknowledgements <- nullApp.NetworkPacketAcknowledgements;
  FennecEngineP.nullAppNetworkStatus <- nullApp.NetworkStatus;

  /* Defined and linked network modules */

  components cuNetC as cuNet;
  components cuNetParamsC;
  cuNet.cuNetParams -> cuNetParamsC;
  FennecEngineP.cuNetControl -> cuNet;
  FennecEngineP.cuNetNetworkAMSend -> cuNet.NetworkAMSend;
  FennecEngineP.cuNetNetworkReceive -> cuNet.NetworkReceive;
  FennecEngineP.cuNetNetworkSnoop -> cuNet.NetworkSnoop;
  FennecEngineP.cuNetNetworkAMPacket -> cuNet.NetworkAMPacket;
  FennecEngineP.cuNetNetworkPacket -> cuNet.NetworkPacket;
  FennecEngineP.cuNetNetworkPacketAcknowledgements -> cuNet.NetworkPacketAcknowledgements;
  FennecEngineP.cuNetNetworkStatus -> cuNet.NetworkStatus;
  FennecEngineP.cuNetMacAMSend <- cuNet.MacAMSend;
  FennecEngineP.cuNetMacReceive <- cuNet.MacReceive;
  FennecEngineP.cuNetMacSnoop <- cuNet.MacSnoop;
  FennecEngineP.cuNetMacAMPacket <- cuNet.MacAMPacket;
  FennecEngineP.cuNetMacPacket <- cuNet.MacPacket;
  FennecEngineP.cuNetMacPacketAcknowledgements <- cuNet.MacPacketAcknowledgements;
  FennecEngineP.cuNetMacStatus <- cuNet.MacStatus;

  components nullNetC as nullNet;
  components nullNetParamsC;
  nullNet.nullNetParams -> nullNetParamsC;
  FennecEngineP.nullNetControl -> nullNet;
  FennecEngineP.nullNetNetworkAMSend -> nullNet.NetworkAMSend;
  FennecEngineP.nullNetNetworkReceive -> nullNet.NetworkReceive;
  FennecEngineP.nullNetNetworkSnoop -> nullNet.NetworkSnoop;
  FennecEngineP.nullNetNetworkAMPacket -> nullNet.NetworkAMPacket;
  FennecEngineP.nullNetNetworkPacket -> nullNet.NetworkPacket;
  FennecEngineP.nullNetNetworkPacketAcknowledgements -> nullNet.NetworkPacketAcknowledgements;
  FennecEngineP.nullNetNetworkStatus -> nullNet.NetworkStatus;
  FennecEngineP.nullNetMacAMSend <- nullNet.MacAMSend;
  FennecEngineP.nullNetMacReceive <- nullNet.MacReceive;
  FennecEngineP.nullNetMacSnoop <- nullNet.MacSnoop;
  FennecEngineP.nullNetMacAMPacket <- nullNet.MacAMPacket;
  FennecEngineP.nullNetMacPacket <- nullNet.MacPacket;
  FennecEngineP.nullNetMacPacketAcknowledgements <- nullNet.MacPacketAcknowledgements;
  FennecEngineP.nullNetMacStatus <- nullNet.MacStatus;

  /* Defined and linked mac */

  components cuMacC as cuMac;
  components cuMacParamsC;
  cuMac.cuMacParams -> cuMacParamsC;
  FennecEngineP.cuMacControl -> cuMac;
  FennecEngineP.cuMacMacAMSend -> cuMac.MacAMSend;
  FennecEngineP.cuMacMacReceive -> cuMac.MacReceive;
  FennecEngineP.cuMacMacSnoop -> cuMac.MacSnoop;
  FennecEngineP.cuMacMacPacket -> cuMac.MacPacket;
  FennecEngineP.cuMacMacAMPacket -> cuMac.MacAMPacket;
  FennecEngineP.cuMacMacPacketAcknowledgements -> cuMac.MacPacketAcknowledgements;
  FennecEngineP.cuMacMacStatus -> cuMac.MacStatus;
  FennecEngineP.cuMacRadioReceive <- cuMac.RadioReceive;
  FennecEngineP.cuMacRadioStatus <- cuMac.RadioStatus;
  FennecEngineP.cuMacRadioResource <- cuMac.RadioResource;
  FennecEngineP.cuMacRadioConfig <- cuMac.RadioConfig;
  FennecEngineP.cuMacRadioPower <- cuMac.RadioPower;
  FennecEngineP.cuMacReadRssi <- cuMac.ReadRssi;
  FennecEngineP.cuMacRadioTransmit <- cuMac.RadioTransmit;
  FennecEngineP.cuMacPacketIndicator <- cuMac.PacketIndicator;
  FennecEngineP.cuMacEnergyIndicator <- cuMac.EnergyIndicator;
  FennecEngineP.cuMacByteIndicator <- cuMac.ByteIndicator;
  FennecEngineP.cuMacRadioControl <- cuMac.RadioControl;
  components csmacaMacC as csmacaMac;
  components csmacaMacParamsC;
  csmacaMac.csmacaMacParams -> csmacaMacParamsC;
  FennecEngineP.csmacaMacControl -> csmacaMac;
  FennecEngineP.csmacaMacMacAMSend -> csmacaMac.MacAMSend;
  FennecEngineP.csmacaMacMacReceive -> csmacaMac.MacReceive;
  FennecEngineP.csmacaMacMacSnoop -> csmacaMac.MacSnoop;
  FennecEngineP.csmacaMacMacPacket -> csmacaMac.MacPacket;
  FennecEngineP.csmacaMacMacAMPacket -> csmacaMac.MacAMPacket;
  FennecEngineP.csmacaMacMacPacketAcknowledgements -> csmacaMac.MacPacketAcknowledgements;
  FennecEngineP.csmacaMacMacStatus -> csmacaMac.MacStatus;
  FennecEngineP.csmacaMacRadioReceive <- csmacaMac.RadioReceive;
  FennecEngineP.csmacaMacRadioStatus <- csmacaMac.RadioStatus;
  FennecEngineP.csmacaMacRadioResource <- csmacaMac.RadioResource;
  FennecEngineP.csmacaMacRadioConfig <- csmacaMac.RadioConfig;
  FennecEngineP.csmacaMacRadioPower <- csmacaMac.RadioPower;
  FennecEngineP.csmacaMacReadRssi <- csmacaMac.ReadRssi;
  FennecEngineP.csmacaMacRadioTransmit <- csmacaMac.RadioTransmit;
  FennecEngineP.csmacaMacPacketIndicator <- csmacaMac.PacketIndicator;
  FennecEngineP.csmacaMacEnergyIndicator <- csmacaMac.EnergyIndicator;
  FennecEngineP.csmacaMacByteIndicator <- csmacaMac.ByteIndicator;
  FennecEngineP.csmacaMacRadioControl <- csmacaMac.RadioControl;
  components tdmaMacC as tdmaMac;
  components tdmaMacParamsC;
  tdmaMac.tdmaMacParams -> tdmaMacParamsC;
  FennecEngineP.tdmaMacControl -> tdmaMac;
  FennecEngineP.tdmaMacMacAMSend -> tdmaMac.MacAMSend;
  FennecEngineP.tdmaMacMacReceive -> tdmaMac.MacReceive;
  FennecEngineP.tdmaMacMacSnoop -> tdmaMac.MacSnoop;
  FennecEngineP.tdmaMacMacPacket -> tdmaMac.MacPacket;
  FennecEngineP.tdmaMacMacAMPacket -> tdmaMac.MacAMPacket;
  FennecEngineP.tdmaMacMacPacketAcknowledgements -> tdmaMac.MacPacketAcknowledgements;
  FennecEngineP.tdmaMacMacStatus -> tdmaMac.MacStatus;
  FennecEngineP.tdmaMacRadioReceive <- tdmaMac.RadioReceive;
  FennecEngineP.tdmaMacRadioStatus <- tdmaMac.RadioStatus;
  FennecEngineP.tdmaMacRadioResource <- tdmaMac.RadioResource;
  FennecEngineP.tdmaMacRadioConfig <- tdmaMac.RadioConfig;
  FennecEngineP.tdmaMacRadioPower <- tdmaMac.RadioPower;
  FennecEngineP.tdmaMacReadRssi <- tdmaMac.ReadRssi;
  FennecEngineP.tdmaMacRadioTransmit <- tdmaMac.RadioTransmit;
  FennecEngineP.tdmaMacPacketIndicator <- tdmaMac.PacketIndicator;
  FennecEngineP.tdmaMacEnergyIndicator <- tdmaMac.EnergyIndicator;
  FennecEngineP.tdmaMacByteIndicator <- tdmaMac.ByteIndicator;
  FennecEngineP.tdmaMacRadioControl <- tdmaMac.RadioControl;
  components nullMacC as nullMac;
  components nullMacParamsC;
  nullMac.nullMacParams -> nullMacParamsC;
  FennecEngineP.nullMacControl -> nullMac;
  FennecEngineP.nullMacMacAMSend -> nullMac.MacAMSend;
  FennecEngineP.nullMacMacReceive -> nullMac.MacReceive;
  FennecEngineP.nullMacMacSnoop -> nullMac.MacSnoop;
  FennecEngineP.nullMacMacPacket -> nullMac.MacPacket;
  FennecEngineP.nullMacMacAMPacket -> nullMac.MacAMPacket;
  FennecEngineP.nullMacMacPacketAcknowledgements -> nullMac.MacPacketAcknowledgements;
  FennecEngineP.nullMacMacStatus -> nullMac.MacStatus;
  FennecEngineP.nullMacRadioReceive <- nullMac.RadioReceive;
  FennecEngineP.nullMacRadioStatus <- nullMac.RadioStatus;
  FennecEngineP.nullMacRadioResource <- nullMac.RadioResource;
  FennecEngineP.nullMacRadioConfig <- nullMac.RadioConfig;
  FennecEngineP.nullMacRadioPower <- nullMac.RadioPower;
  FennecEngineP.nullMacReadRssi <- nullMac.ReadRssi;
  FennecEngineP.nullMacRadioTransmit <- nullMac.RadioTransmit;
  FennecEngineP.nullMacPacketIndicator <- nullMac.PacketIndicator;
  FennecEngineP.nullMacEnergyIndicator <- nullMac.EnergyIndicator;
  FennecEngineP.nullMacByteIndicator <- nullMac.ByteIndicator;
  FennecEngineP.nullMacRadioControl <- nullMac.RadioControl;
  /* Defined and linked radios */

  components cc2420RadioC as cc2420Radio;
  components cc2420RadioParamsC;
  cc2420Radio.cc2420RadioParams -> cc2420RadioParamsC;
  FennecEngineP.cc2420RadioControl -> cc2420Radio;
  FennecEngineP.cc2420RadioRadioReceive -> cc2420Radio.RadioReceive;
  FennecEngineP.cc2420RadioRadioStatus -> cc2420Radio.RadioStatus;
  FennecEngineP.cc2420RadioRadioResource -> cc2420Radio.RadioResource;
  FennecEngineP.cc2420RadioRadioConfig -> cc2420Radio.RadioConfig;
  FennecEngineP.cc2420RadioRadioPower -> cc2420Radio.RadioPower;
  FennecEngineP.cc2420RadioReadRssi -> cc2420Radio.ReadRssi;
  FennecEngineP.cc2420RadioRadioTransmit -> cc2420Radio.RadioTransmit;
  FennecEngineP.cc2420RadioPacketIndicator -> cc2420Radio.PacketIndicator;
  FennecEngineP.cc2420RadioEnergyIndicator -> cc2420Radio.EnergyIndicator;
  FennecEngineP.cc2420RadioByteIndicator -> cc2420Radio.ByteIndicator;
  FennecEngineP.cc2420RadioRadioControl -> cc2420Radio.RadioControl;
  components nullRadioC as nullRadio;
  components nullRadioParamsC;
  nullRadio.nullRadioParams -> nullRadioParamsC;
  FennecEngineP.nullRadioControl -> nullRadio;
  FennecEngineP.nullRadioRadioReceive -> nullRadio.RadioReceive;
  FennecEngineP.nullRadioRadioStatus -> nullRadio.RadioStatus;
  FennecEngineP.nullRadioRadioResource -> nullRadio.RadioResource;
  FennecEngineP.nullRadioRadioConfig -> nullRadio.RadioConfig;
  FennecEngineP.nullRadioRadioPower -> nullRadio.RadioPower;
  FennecEngineP.nullRadioReadRssi -> nullRadio.ReadRssi;
  FennecEngineP.nullRadioRadioTransmit -> nullRadio.RadioTransmit;
  FennecEngineP.nullRadioPacketIndicator -> nullRadio.PacketIndicator;
  FennecEngineP.nullRadioEnergyIndicator -> nullRadio.EnergyIndicator;
  FennecEngineP.nullRadioByteIndicator -> nullRadio.ByteIndicator;
  FennecEngineP.nullRadioRadioControl -> nullRadio.RadioControl;

}
