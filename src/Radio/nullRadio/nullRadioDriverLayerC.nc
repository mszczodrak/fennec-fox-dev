#include <RadioConfig.h>
#include <nullRadioDriverLayer.h>

#include <AM.h>

configuration capeDriverLayerC {
provides interface RadioReceive;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

components CapePacketModelC as CapePacketModelC;
components CpmModelC;
components capeDriverLayerP;

RadioState = capeDriverLayerP;
RadioReceive = capeDriverLayerP.RadioReceive;

PacketTransmitPower = capeDriverLayerP.PacketTransmitPower;
PacketRSSI = capeDriverLayerP.PacketRSSI;
PacketTimeSync = capeDriverLayerP.PacketTimeSync;
PacketLinkQuality = capeDriverLayerP.PacketLinkQuality;
RadioLinkPacketMetadata = capeDriverLayerP.RadioLinkPacketMetadata;

RadioResource = capeDriverLayerP.RadioResource;

RadioBuffer = capeDriverLayerP.RadioBuffer;
RadioPacket = capeDriverLayerP.RadioPacket;
RadioSend = capeDriverLayerP.RadioSend;

capeDriverLayerP.AMControl -> CapePacketModelC;
capeDriverLayerP.Model -> CapePacketModelC.Packet;
RadioCCA = CapePacketModelC.RadioCCA;

CapePacketModelC.GainRadioModel -> CpmModelC.Model;
}
