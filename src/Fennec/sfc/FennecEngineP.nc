/* Swift Fox generated code for Fennec Fox Application module */
#include <Fennec.h>
#include "engine.h"
#define MODULE_RESPONSE_DELAY    200

module FennecEngineP {

  provides interface Mgmt;
  provides interface Module;

  uses interface Timer<TMilli>;
  /* Application Modules */

  /* Application  Module: ControlUnitApp */
  uses interface Mgmt as ControlUnitAppControl;
  provides interface AMSend as ControlUnitAppNetworkAMSend;
  provides interface Receive as ControlUnitAppNetworkReceive;
  provides interface Receive as ControlUnitAppNetworkSnoop;
  provides interface Packet as ControlUnitAppNetworkPacket;
  provides interface AMPacket as ControlUnitAppNetworkAMPacket;
  provides interface PacketAcknowledgements as ControlUnitAppNetworkPacketAcknowledgements;
  provides interface ModuleStatus as ControlUnitAppNetworkStatus;

  /* Application  Module: BlinkApp */
  uses interface Mgmt as BlinkAppControl;
  provides interface AMSend as BlinkAppNetworkAMSend;
  provides interface Receive as BlinkAppNetworkReceive;
  provides interface Receive as BlinkAppNetworkSnoop;
  provides interface Packet as BlinkAppNetworkPacket;
  provides interface AMPacket as BlinkAppNetworkAMPacket;
  provides interface PacketAcknowledgements as BlinkAppNetworkPacketAcknowledgements;
  provides interface ModuleStatus as BlinkAppNetworkStatus;

  /* Network Modules */

  /* Network Module: cuNet */
  uses interface Mgmt as cuNetControl;
  uses interface AMSend as cuNetNetworkAMSend;
  uses interface Receive as cuNetNetworkReceive;
  uses interface Receive as cuNetNetworkSnoop;
  uses interface AMPacket as cuNetNetworkAMPacket;
  uses interface Packet as cuNetNetworkPacket;
  uses interface PacketAcknowledgements as cuNetNetworkPacketAcknowledgements;
  uses interface ModuleStatus as cuNetNetworkStatus;
  provides interface AMSend as cuNetMacAMSend;
  provides interface Receive as cuNetMacReceive;
  provides interface Receive as cuNetMacSnoop;
  provides interface Packet as cuNetMacPacket;
  provides interface AMPacket as cuNetMacAMPacket;
  provides interface PacketAcknowledgements as cuNetMacPacketAcknowledgements;
  provides interface ModuleStatus as cuNetMacStatus;

  /* Network Module: nullNet */
  uses interface Mgmt as nullNetControl;
  uses interface AMSend as nullNetNetworkAMSend;
  uses interface Receive as nullNetNetworkReceive;
  uses interface Receive as nullNetNetworkSnoop;
  uses interface AMPacket as nullNetNetworkAMPacket;
  uses interface Packet as nullNetNetworkPacket;
  uses interface PacketAcknowledgements as nullNetNetworkPacketAcknowledgements;
  uses interface ModuleStatus as nullNetNetworkStatus;
  provides interface AMSend as nullNetMacAMSend;
  provides interface Receive as nullNetMacReceive;
  provides interface Receive as nullNetMacSnoop;
  provides interface Packet as nullNetMacPacket;
  provides interface AMPacket as nullNetMacAMPacket;
  provides interface PacketAcknowledgements as nullNetMacPacketAcknowledgements;
  provides interface ModuleStatus as nullNetMacStatus;

  /* MAC Modules */

  /* MAC Module: cuMac */
  uses interface Mgmt as cuMacControl;
  uses interface AMSend as cuMacMacAMSend;
  uses interface Receive as cuMacMacReceive;
  uses interface Receive as cuMacMacSnoop;
  uses interface Packet as cuMacMacPacket;
  uses interface AMPacket as cuMacMacAMPacket;
  uses interface PacketAcknowledgements as cuMacMacPacketAcknowledgements;
  uses interface ModuleStatus as cuMacMacStatus;
  provides interface Receive as cuMacRadioReceive;
  provides interface ModuleStatus as cuMacRadioStatus;
  provides interface Resource as cuMacRadioResource;
  provides interface RadioConfig as cuMacRadioConfig;
  provides interface RadioPower as cuMacRadioPower;
  provides interface Read<uint16_t> as cuMacReadRssi;
  provides interface RadioTransmit as cuMacRadioTransmit;
  provides interface ReceiveIndicator as cuMacPacketIndicator;
  provides interface ReceiveIndicator as cuMacEnergyIndicator;
  provides interface ReceiveIndicator as cuMacByteIndicator;
  provides interface SplitControl as cuMacRadioControl;
  /* MAC Module: csmacaMac */
  uses interface Mgmt as csmacaMacControl;
  uses interface AMSend as csmacaMacMacAMSend;
  uses interface Receive as csmacaMacMacReceive;
  uses interface Receive as csmacaMacMacSnoop;
  uses interface Packet as csmacaMacMacPacket;
  uses interface AMPacket as csmacaMacMacAMPacket;
  uses interface PacketAcknowledgements as csmacaMacMacPacketAcknowledgements;
  uses interface ModuleStatus as csmacaMacMacStatus;
  provides interface Receive as csmacaMacRadioReceive;
  provides interface ModuleStatus as csmacaMacRadioStatus;
  provides interface Resource as csmacaMacRadioResource;
  provides interface RadioConfig as csmacaMacRadioConfig;
  provides interface RadioPower as csmacaMacRadioPower;
  provides interface Read<uint16_t> as csmacaMacReadRssi;
  provides interface RadioTransmit as csmacaMacRadioTransmit;
  provides interface ReceiveIndicator as csmacaMacPacketIndicator;
  provides interface ReceiveIndicator as csmacaMacEnergyIndicator;
  provides interface ReceiveIndicator as csmacaMacByteIndicator;
  provides interface SplitControl as csmacaMacRadioControl;
  /* Radio Modules */

  /* Radio Module: cc2420Radio */
  uses interface Mgmt as cc2420RadioControl;
  uses interface Receive as cc2420RadioRadioReceive;
  uses interface ModuleStatus as cc2420RadioRadioStatus;
  uses interface Resource as cc2420RadioRadioResource;
  uses interface RadioConfig as cc2420RadioRadioConfig;
  uses interface RadioPower as cc2420RadioRadioPower;
  uses interface Read<uint16_t> as cc2420RadioReadRssi;
  uses interface RadioTransmit as cc2420RadioRadioTransmit;
  uses interface ReceiveIndicator as cc2420RadioPacketIndicator;
  uses interface ReceiveIndicator as cc2420RadioEnergyIndicator;
  uses interface ReceiveIndicator as cc2420RadioByteIndicator;
  uses interface SplitControl as cc2420RadioRadioControl;
}

implementation {

  void ctrl_state_done(uint8_t status, uint8_t ctrl) @C() {
    if (ctrl == ON) {
      signal Mgmt.startDone(SUCCESS);
    } else {
      signal Mgmt.stopDone(SUCCESS);
    }
  }

  void ctrl_module(uint16_t module_id, uint8_t ctrl) @C() {
    switch(module_id) {

      case 1:
        if (ctrl) {
          call ControlUnitAppControl.start();
        } else {
          call ControlUnitAppControl.stop();
        }
        break;

      case 2:
        if (ctrl) {
          call cuNetControl.start();
        } else {
          call cuNetControl.stop();
        }
        break;

      case 3:
        if (ctrl) {
          call cuMacControl.start();
        } else {
          call cuMacControl.stop();
        }
        break;

      case 4:
        if (ctrl) {
          call cc2420RadioControl.start();
        } else {
          call cc2420RadioControl.stop();
        }
        break;

      case 5:
        if (ctrl) {
          call BlinkAppControl.start();
        } else {
          call BlinkAppControl.stop();
        }
        break;

      case 6:
        if (ctrl) {
          call nullNetControl.start();
        } else {
          call nullNetControl.stop();
        }
        break;

      case 7:
        if (ctrl) {
          call csmacaMacControl.start();
        } else {
          call csmacaMacControl.stop();
        }
        break;

      default:
    }
    call Timer.startOneShot(MODULE_RESPONSE_DELAY);
  }

  task void configure_engine() {
    call Timer.stop();
    ctrl_module_done(0);
  }

  event void Timer.fired() {
    ctrl_module_done(1);
  }

  command error_t Mgmt.start() {
    ctrl_state(ON);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    ctrl_state(OFF);
    return SUCCESS;
  }

  error_t AMSend_send(uint16_t module_id, uint8_t to_layer, am_addr_t addr, message_t* msg, uint8_t len) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMSend.send(addr, msg, len);

      case 6:
        return call nullNetNetworkAMSend.send(addr, msg, len);

      case 3:
        return call cuMacMacAMSend.send(addr, msg, len);

      case 7:
        return call csmacaMacMacAMSend.send(addr, msg, len);

      default:
        return FAIL;
    }
  }

  error_t AMSend_cancel(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMSend.cancel(msg);

      case 6:
        return call nullNetNetworkAMSend.cancel(msg);

      case 3:
        return call cuMacMacAMSend.cancel(msg);

      case 7:
        return call csmacaMacMacAMSend.cancel(msg);

      default:
        return FAIL;
    }
  }

  void* AMSend_getPayload(uint16_t module_id, uint8_t to_layer, message_t *msg, uint8_t len) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMSend.getPayload(msg, len);

      case 6:
        return call nullNetNetworkAMSend.getPayload(msg, len);

      case 3:
        return call cuMacMacAMSend.getPayload(msg, len);

      case 7:
        return call csmacaMacMacAMSend.getPayload(msg, len);

      default:
        return NULL;
    }
  }

  uint8_t AMSend_maxPayloadLength(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 2:
        return call cuNetNetworkAMSend.maxPayloadLength();

      case 6:
        return call nullNetNetworkAMSend.maxPayloadLength();

      case 3:
        return call cuMacMacAMSend.maxPayloadLength();

      case 7:
        return call csmacaMacMacAMSend.maxPayloadLength();

      default:
        return 0;
    }
  }

  am_addr_t AMPacket_address(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.address();

      case 6:
        return call nullNetNetworkAMPacket.address();

      case 3:
        return call cuMacMacAMPacket.address();

      case 7:
        return call csmacaMacMacAMPacket.address();

      default:
        return 0;
    }
  }

  am_addr_t AMPacket_destination(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.destination(msg);
      case 6:
        return call nullNetNetworkAMPacket.destination(msg);
      case 3:
        return call cuMacMacAMPacket.destination(msg);
      case 7:
        return call csmacaMacMacAMPacket.destination(msg);
      default:
        return 0;
    }
  }

  am_addr_t AMPacket_source(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.source(msg);

      case 6:
        return call nullNetNetworkAMPacket.source(msg);

      case 3:
        return call cuMacMacAMPacket.source(msg);

      case 7:
        return call csmacaMacMacAMPacket.source(msg);

      default:
        return 0;
    }
  }

  void AMPacket_setDestination(uint16_t module_id, uint8_t to_layer, message_t *msg, am_addr_t addr) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.setDestination(msg, addr);

      case 6:
        return call nullNetNetworkAMPacket.setDestination(msg, addr);

      case 3:
        return call cuMacMacAMPacket.setDestination(msg, addr);

      case 7:
        return call csmacaMacMacAMPacket.setDestination(msg, addr);

      default:
        return;
    }
  }

  void AMPacket_setSource(uint16_t module_id, uint8_t to_layer, message_t *msg, am_addr_t addr) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.setSource(msg, addr);

      case 6:
        return call nullNetNetworkAMPacket.setSource(msg, addr);

      case 3:
        return call cuMacMacAMPacket.setSource(msg, addr);

      case 7:
        return call csmacaMacMacAMPacket.setSource(msg, addr);

      default:
        return;
    }
  }

  bool AMPacket_isForMe(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.isForMe(msg);

      case 6:
        return call nullNetNetworkAMPacket.isForMe(msg);

      case 3:
        return call cuMacMacAMPacket.isForMe(msg);

      case 7:
        return call csmacaMacMacAMPacket.isForMe(msg);

      default:
        return 0;
    }
  }

  am_id_t AMPacket_type(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.type(msg);

      case 6:
        return call nullNetNetworkAMPacket.type(msg);

      case 3:
        return call cuMacMacAMPacket.type(msg);

      case 7:
        return call csmacaMacMacAMPacket.type(msg);

      default:
        return 0;
    }
  }

  void AMPacket_setType(uint16_t module_id, uint8_t to_layer, message_t *msg, am_id_t t) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.setType(msg, t);

      case 6:
        return call nullNetNetworkAMPacket.setType(msg, t);

      case 3:
        return call cuMacMacAMPacket.setType(msg, t);

      case 7:
        return call csmacaMacMacAMPacket.setType(msg, t);

      default:
        return;
    }
  }

  am_group_t AMPacket_group(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.group(msg);

      case 6:
        return call nullNetNetworkAMPacket.group(msg);

      case 3:
        return call cuMacMacAMPacket.group(msg);

      case 7:
        return call csmacaMacMacAMPacket.group(msg);

      default:
        return 0;
    }
  }

  void AMPacket_setGroup(uint16_t module_id, uint8_t to_layer, message_t *msg, am_group_t grp) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.setGroup(msg, grp);

      case 6:
        return call nullNetNetworkAMPacket.setGroup(msg, grp);

      case 3:
        return call cuMacMacAMPacket.setGroup(msg, grp);

      case 7:
        return call csmacaMacMacAMPacket.setGroup(msg, grp);

      default:
        return;
    }
  }

  void* Packet_getPayload(uint16_t module_id, uint8_t to_layer, message_t *msg, uint8_t len) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacket.getPayload(msg, len);

      case 6:
        return call nullNetNetworkPacket.getPayload(msg, len);

      case 3:
        return call cuMacMacPacket.getPayload(msg, len);

      case 7:
        return call csmacaMacMacPacket.getPayload(msg, len);

      default:
        return NULL;
    }
  }

  uint8_t Packet_maxPayloadLength(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 2:
        return call cuNetNetworkPacket.maxPayloadLength();

      case 6:
        return call nullNetNetworkPacket.maxPayloadLength();

      case 3:
        return call cuMacMacPacket.maxPayloadLength();

      case 7:
        return call csmacaMacMacPacket.maxPayloadLength();

      default:
        return 0;
    }
  }

  am_group_t AMPacket_localGroup(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 2:
        return call cuNetNetworkAMPacket.localGroup();

      case 6:
        return call nullNetNetworkAMPacket.localGroup();

      case 3:
        return call cuMacMacAMPacket.localGroup();

      case 7:
        return call csmacaMacMacAMPacket.localGroup();

      default:
        return 0;
    }
  }

  void Packet_clear(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacket.clear(msg);

      case 6:
        return call nullNetNetworkPacket.clear(msg);

      case 3:
        return call cuMacMacPacket.clear(msg);

      case 7:
        return call csmacaMacMacPacket.clear(msg);

      default:
        return;
    }
  }

  uint8_t Packet_payloadLength(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacket.payloadLength(msg);

      case 6:
        return call nullNetNetworkPacket.payloadLength(msg);

      case 3:
        return call cuMacMacPacket.payloadLength(msg);

      case 7:
        return call csmacaMacMacPacket.payloadLength(msg);

      default:
        return 0;
    }
  }

  void Packet_setPayloadLength(uint16_t module_id, uint8_t to_layer, message_t *msg, uint8_t len) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacket.setPayloadLength(msg, len);

      case 6:
        return call nullNetNetworkPacket.setPayloadLength(msg, len);

      case 3:
        return call cuMacMacPacket.setPayloadLength(msg, len);

      case 7:
        return call csmacaMacMacPacket.setPayloadLength(msg, len);

      default:
        return;
    }
  }

  error_t PacketAcknowledgements_requestAck(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacketAcknowledgements.requestAck(msg);

      case 6:
        return call nullNetNetworkPacketAcknowledgements.requestAck(msg);

      case 3:
        return call cuMacMacPacketAcknowledgements.requestAck(msg);

      case 7:
        return call csmacaMacMacPacketAcknowledgements.requestAck(msg);

      default:
        return FAIL;
    }
  }

  error_t PacketAcknowledgements_noAck(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacketAcknowledgements.noAck(msg);

      case 6:
        return call nullNetNetworkPacketAcknowledgements.noAck(msg);

      case 3:
        return call cuMacMacPacketAcknowledgements.noAck(msg);

      case 7:
        return call csmacaMacMacPacketAcknowledgements.noAck(msg);

      default:
        return FAIL;
    }
  }

  bool PacketAcknowledgements_wasAcked(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 2:
        return call cuNetNetworkPacketAcknowledgements.wasAcked(msg);

      case 6:
        return call nullNetNetworkPacketAcknowledgements.wasAcked(msg);

      case 3:
        return call cuMacMacPacketAcknowledgements.wasAcked(msg);

      case 7:
        return call csmacaMacMacPacketAcknowledgements.wasAcked(msg);

      default:
        return 0;
    }
  }

  error_t RadioConfig_sync(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.sync();

      default:
        return 0;
    }
  }

  uint8_t RadioConfig_getChannel(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.getChannel();

      default:
        return 0;
    }
  }

  void RadioConfig_setChannel(uint16_t module_id, uint8_t to_layer, uint8_t channel) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.setChannel( channel );

      default:
        return;
    }
  }

  uint16_t RadioConfig_getShortAddr(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.getShortAddr();

      default:
        return 0;
    }
  }

  void RadioConfig_setShortAddr(uint16_t module_id, uint8_t to_layer, uint16_t address) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.setShortAddr(address);

      default:
        return;
    }
  }

  uint16_t RadioConfig_getPanAddr(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.getPanAddr();

      default:
        return 0;
    }
  }

  void RadioConfig_setPanAddr(uint16_t module_id, uint8_t to_layer, uint16_t address) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.setPanAddr(address);

      default:
        return;
    }
  }

  void RadioConfig_setAddressRecognition(uint16_t module_id, uint8_t to_layer, bool enableAddressRecognition, bool useHwAddressRecognition) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.setAddressRecognition(enableAddressRecognition, useHwAddressRecognition);

      default:
        return;
    }
  }

  bool RadioConfig_isAddressRecognitionEnabled(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.isAddressRecognitionEnabled();

      default:
        return 0;
    }
  }

  bool RadioConfig_isHwAddressRecognitionDefault(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.isHwAddressRecognitionDefault();

      default:
        return 0;
    }
  }

  void RadioConfig_setAutoAck(uint16_t module_id, uint8_t to_layer, bool enableAutoAck, bool hwAutoAck) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.setAutoAck(enableAutoAck, hwAutoAck);

      default:
        return;
    }
  }

  bool RadioConfig_isHwAutoAckDefault(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.isHwAutoAckDefault();

      default:
        return 0;
    }
  }

  bool RadioConfig_isAutoAckEnabled(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioConfig.isAutoAckEnabled();

      default:
        return 0;
    }
  }

  error_t RadioPower_startVReg(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.startVReg();

      default:
        return 0;
    }
  }

  error_t RadioPower_stopVReg(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.stopVReg();

      default:
        return 0;
    }
  }

  error_t RadioPower_startOscillator(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.startOscillator();

      default:
        return 0;
    }
  }

  error_t RadioPower_stopOscillator(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.stopOscillator();

      default:
        return 0;
    }
  }

  error_t RadioPower_rxOn(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.rxOn();

      default:
        return 0;
    }
  }

  error_t RadioPower_rfOff(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioPower.rfOff();

      default:
        return 0;
    }
  }

  error_t ReadRssi_read(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioReadRssi.read();

      default:
        return 0;
    }
  }

  error_t RadioResource_request(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioResource.request();

      default:
        return FAIL;
    }
  }

  error_t RadioResource_immediateRequest(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioResource.immediateRequest();

      default:
        return 0;
    }
  }

  error_t RadioResource_release(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioResource.release();

      default:
        return 0;
    }
  }

  bool RadioResource_isOwner(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioResource.isOwner();

      default:
        return 0;
    }
  }

  error_t RadioControl_start(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioControl.start();

      default:
        return FAIL;
    }
  }

  error_t RadioControl_stop(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioControl.stop();

      default:
        return FAIL;
    }
  }

  void RadioTransmit_cancel(uint16_t module_id, uint8_t to_layer, message_t *msg) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioRadioTransmit.cancel(msg);

      default:
        return;
    }
  }

  error_t RadioTransmit_load(uint16_t module_id, uint8_t to_layer, message_t* msg) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 4:
        return call cc2420RadioRadioTransmit.load(msg);

      default:
        return FAIL;
    }
  }

  error_t RadioTransmit_send(uint16_t module_id, uint8_t to_layer, message_t* msg, bool useCca) {
    if (msg->conf != POLICY_CONFIGURATION) msg->conf = get_conf_id();
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 4:
        return call cc2420RadioRadioTransmit.send(msg, useCca);

      default:
        return FAIL;
    }
  }

  bool PacketIndicator_isReceiving(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioPacketIndicator.isReceiving();

      default:
        return 0;
    }
  }

  bool EnergyIndicator_isReceiving(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioEnergyIndicator.isReceiving();

      default:
        return 0;
    }
  }

  bool ByteIndicator_isReceiving(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 4:
        return call cc2420RadioByteIndicator.isReceiving();

      default:
        return 0;
    }
  }

  void sendDone(uint16_t module_id, uint8_t to_layer, message_t* msg, error_t error) {
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 1:
        signal ControlUnitAppNetworkAMSend.sendDone(msg, error);
        return;

      case 5:
        signal BlinkAppNetworkAMSend.sendDone(msg, error);
        return;

      case 2:
        signal cuNetMacAMSend.sendDone(msg, error);
        return;

      case 6:
        signal nullNetMacAMSend.sendDone(msg, error);
        return;

      default:
        return;
    }

  }

  message_t* receive(uint16_t module_id, uint8_t to_layer, message_t* msg, void* payload, uint8_t len) {
    if (to_layer == F_RADIO) check_configuration(msg->conf);
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 1:
        return signal ControlUnitAppNetworkReceive.receive(msg, payload, len);

      case 5:
        return signal BlinkAppNetworkReceive.receive(msg, payload, len);

      case 2:
        return signal cuNetMacReceive.receive(msg, payload, len);

      case 6:
        return signal nullNetMacReceive.receive(msg, payload, len);

      case 3:
        return signal cuMacRadioReceive.receive(msg, payload, len);

      case 7:
        return signal csmacaMacRadioReceive.receive(msg, payload, len);

      default:
        return msg;

      }
  }

  message_t* snoop(uint16_t module_id, uint8_t to_layer, message_t* msg, void* payload, uint8_t len) {
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 1:
        return signal ControlUnitAppNetworkSnoop.receive(msg, payload, len);

      case 5:
        return signal BlinkAppNetworkSnoop.receive(msg, payload, len);

      case 2:
        return signal cuNetMacSnoop.receive(msg, payload, len);

      case 6:
        return signal nullNetMacSnoop.receive(msg, payload, len);

      default:
        return msg;

    }
  }

  void status(uint16_t module_id, uint8_t to_layer, uint8_t layer, uint8_t status_flag) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 1:
        return signal ControlUnitAppNetworkStatus.status(layer, status_flag);

      case 5:
        return signal BlinkAppNetworkStatus.status(layer, status_flag);

      case 2:
        return signal cuNetMacStatus.status(layer, status_flag);

      case 6:
        return signal nullNetMacStatus.status(layer, status_flag);

      case 3:
        return signal cuMacRadioStatus.status(layer, status_flag);

      case 7:
        return signal csmacaMacRadioStatus.status(layer, status_flag);

    }
  }

  void syncDone(uint16_t module_id, uint8_t to_layer, error_t error) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioConfig.syncDone(error);

      case 7:
        return signal csmacaMacRadioConfig.syncDone(error);

    }
  }

  void startVRegDone(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioPower.startVRegDone();

      case 7:
        return signal csmacaMacRadioPower.startVRegDone();

    }
  }

  void startOscillatorDone(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioPower.startOscillatorDone();

      case 7:
        return signal csmacaMacRadioPower.startOscillatorDone();

    }
  }

  void readRssiDone(uint16_t module_id, uint8_t to_layer, error_t error, uint16_t rssi) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacReadRssi.readDone(error, rssi);

      case 7:
        return signal csmacaMacReadRssi.readDone(error, rssi);

    }
  }

  void granted(uint16_t module_id, uint8_t to_layer) {
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioResource.granted();

      case 7:
        return signal csmacaMacRadioResource.granted();

    }
  }

  void transmitLoadDone(uint16_t module_id, uint8_t to_layer, message_t *msg, error_t error) {
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 3:
        return signal cuMacRadioTransmit.loadDone(msg, error);

      case 7:
        return signal csmacaMacRadioTransmit.loadDone(msg, error);

    }
  }

  void transmitSendDone(uint16_t module_id, uint8_t to_layer, message_t *msg, error_t error) {
    switch( get_module_id(module_id, msg->conf, to_layer) ) {
      case 3:
        return signal cuMacRadioTransmit.sendDone(msg, error);

      case 7:
        return signal csmacaMacRadioTransmit.sendDone(msg, error);

    }
  }

  void radioControlStartDone(uint16_t module_id, uint8_t to_layer, error_t error) {
    switch( configurations[POLICY_CONF_ID].mac ) {
      case 3:
        signal cuMacRadioControl.startDone(error);
        break;

      case 7:
        signal csmacaMacRadioControl.startDone(error);
        break;

    }
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioControl.startDone(error);

      case 7:
        return signal csmacaMacRadioControl.startDone(error);

    }
  }

  void radioControlStopDone(uint16_t module_id, uint8_t to_layer, error_t error) {
    switch( configurations[POLICY_CONF_ID].mac ) {
      case 3:
        signal cuMacRadioControl.stopDone(error);
        break;

      case 7:
        signal csmacaMacRadioControl.stopDone(error);
        break;

    }
    switch( get_module_id(module_id, get_conf_id(), to_layer) ) {
      case 3:
        return signal cuMacRadioControl.stopDone(error);

      case 7:
        return signal csmacaMacRadioControl.stopDone(error);

    }
  }

  event void ControlUnitAppControl.startDone(error_t err){
    post configure_engine();
  }

  event void ControlUnitAppControl.stopDone(error_t err) {
    post configure_engine();
  }

  command error_t ControlUnitAppNetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return AMSend_send(1, F_NETWORK, addr, msg, len);
  }

  command error_t ControlUnitAppNetworkAMSend.cancel(message_t* msg) {
    return AMSend_cancel(1, F_NETWORK, msg);
  }

  command uint8_t ControlUnitAppNetworkAMSend.maxPayloadLength() {
    return AMSend_maxPayloadLength(1, F_NETWORK);
  }

  command void* ControlUnitAppNetworkAMSend.getPayload(message_t* msg, uint8_t len) {
    return AMSend_getPayload(1, F_NETWORK, msg, len);
  }

  command am_addr_t ControlUnitAppNetworkAMPacket.address() {
    return AMPacket_address(1, F_NETWORK);
  }

  command am_addr_t ControlUnitAppNetworkAMPacket.destination(message_t* msg) {
    return AMPacket_destination(1, F_NETWORK, msg);
  }

  command am_addr_t ControlUnitAppNetworkAMPacket.source(message_t* msg) {
    return AMPacket_source(1, F_NETWORK, msg);
  }
  command void ControlUnitAppNetworkAMPacket.setDestination(message_t* msg, am_addr_t addr) {
    return AMPacket_setDestination(1, F_NETWORK, msg, addr);
  }

  command void ControlUnitAppNetworkAMPacket.setSource(message_t* msg, am_addr_t addr) {
    return AMPacket_setSource(1, F_NETWORK, msg, addr);
  }
  command bool ControlUnitAppNetworkAMPacket.isForMe(message_t* msg) {
    return AMPacket_isForMe(1, F_NETWORK, msg);
  }

  command am_id_t ControlUnitAppNetworkAMPacket.type(message_t* msg) {
    return AMPacket_type(1, F_NETWORK, msg);
  }

  command void ControlUnitAppNetworkAMPacket.setType(message_t* msg, am_id_t t) {
    return AMPacket_setType(1, F_NETWORK, msg, t);
  }

  command am_group_t ControlUnitAppNetworkAMPacket.group(message_t* msg) {
    return AMPacket_group(1, F_NETWORK, msg);
  }

  command void ControlUnitAppNetworkAMPacket.setGroup(message_t* msg, am_group_t grp) {
    return AMPacket_setGroup(1, F_NETWORK, msg, grp);
  }
  command am_group_t ControlUnitAppNetworkAMPacket.localGroup() {
    return AMPacket_localGroup(1, F_NETWORK);
  }

  command void ControlUnitAppNetworkPacket.clear(message_t* msg) {
    return Packet_clear(1, F_NETWORK, msg);
  }

  command uint8_t ControlUnitAppNetworkPacket.payloadLength(message_t* msg) {
    return Packet_payloadLength(1, F_NETWORK, msg);
  }

  command void ControlUnitAppNetworkPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return Packet_setPayloadLength(1, F_NETWORK, msg, len);
  }

  command uint8_t ControlUnitAppNetworkPacket.maxPayloadLength() {
    return Packet_maxPayloadLength(1, F_NETWORK);
  }

  command void* ControlUnitAppNetworkPacket.getPayload(message_t* msg, uint8_t len) {
    return Packet_getPayload(1, F_NETWORK, msg, len);
  }

  async command error_t ControlUnitAppNetworkPacketAcknowledgements.requestAck( message_t* msg ) {
    return PacketAcknowledgements_requestAck(1, F_NETWORK, msg);
  }

  async command error_t ControlUnitAppNetworkPacketAcknowledgements.noAck( message_t* msg ) {
    return PacketAcknowledgements_noAck(1, F_NETWORK, msg);
  }

  async command bool ControlUnitAppNetworkPacketAcknowledgements.wasAcked(message_t* msg) {
    return PacketAcknowledgements_wasAcked(1, F_NETWORK, msg);
  }

  event void BlinkAppControl.startDone(error_t err){
    post configure_engine();
  }

  event void BlinkAppControl.stopDone(error_t err) {
    post configure_engine();
  }

  command error_t BlinkAppNetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return AMSend_send(5, F_NETWORK, addr, msg, len);
  }

  command error_t BlinkAppNetworkAMSend.cancel(message_t* msg) {
    return AMSend_cancel(5, F_NETWORK, msg);
  }

  command uint8_t BlinkAppNetworkAMSend.maxPayloadLength() {
    return AMSend_maxPayloadLength(5, F_NETWORK);
  }

  command void* BlinkAppNetworkAMSend.getPayload(message_t* msg, uint8_t len) {
    return AMSend_getPayload(5, F_NETWORK, msg, len);
  }

  command am_addr_t BlinkAppNetworkAMPacket.address() {
    return AMPacket_address(5, F_NETWORK);
  }

  command am_addr_t BlinkAppNetworkAMPacket.destination(message_t* msg) {
    return AMPacket_destination(5, F_NETWORK, msg);
  }

  command am_addr_t BlinkAppNetworkAMPacket.source(message_t* msg) {
    return AMPacket_source(5, F_NETWORK, msg);
  }
  command void BlinkAppNetworkAMPacket.setDestination(message_t* msg, am_addr_t addr) {
    return AMPacket_setDestination(5, F_NETWORK, msg, addr);
  }

  command void BlinkAppNetworkAMPacket.setSource(message_t* msg, am_addr_t addr) {
    return AMPacket_setSource(5, F_NETWORK, msg, addr);
  }
  command bool BlinkAppNetworkAMPacket.isForMe(message_t* msg) {
    return AMPacket_isForMe(5, F_NETWORK, msg);
  }

  command am_id_t BlinkAppNetworkAMPacket.type(message_t* msg) {
    return AMPacket_type(5, F_NETWORK, msg);
  }

  command void BlinkAppNetworkAMPacket.setType(message_t* msg, am_id_t t) {
    return AMPacket_setType(5, F_NETWORK, msg, t);
  }

  command am_group_t BlinkAppNetworkAMPacket.group(message_t* msg) {
    return AMPacket_group(5, F_NETWORK, msg);
  }

  command void BlinkAppNetworkAMPacket.setGroup(message_t* msg, am_group_t grp) {
    return AMPacket_setGroup(5, F_NETWORK, msg, grp);
  }
  command am_group_t BlinkAppNetworkAMPacket.localGroup() {
    return AMPacket_localGroup(5, F_NETWORK);
  }

  command void BlinkAppNetworkPacket.clear(message_t* msg) {
    return Packet_clear(5, F_NETWORK, msg);
  }

  command uint8_t BlinkAppNetworkPacket.payloadLength(message_t* msg) {
    return Packet_payloadLength(5, F_NETWORK, msg);
  }

  command void BlinkAppNetworkPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return Packet_setPayloadLength(5, F_NETWORK, msg, len);
  }

  command uint8_t BlinkAppNetworkPacket.maxPayloadLength() {
    return Packet_maxPayloadLength(5, F_NETWORK);
  }

  command void* BlinkAppNetworkPacket.getPayload(message_t* msg, uint8_t len) {
    return Packet_getPayload(5, F_NETWORK, msg, len);
  }

  async command error_t BlinkAppNetworkPacketAcknowledgements.requestAck( message_t* msg ) {
    return PacketAcknowledgements_requestAck(5, F_NETWORK, msg);
  }

  async command error_t BlinkAppNetworkPacketAcknowledgements.noAck( message_t* msg ) {
    return PacketAcknowledgements_noAck(5, F_NETWORK, msg);
  }

  async command bool BlinkAppNetworkPacketAcknowledgements.wasAcked(message_t* msg) {
    return PacketAcknowledgements_wasAcked(5, F_NETWORK, msg);
  }

  event void cuNetControl.startDone(error_t err) {
    post configure_engine();
  }

  event void cuNetControl.stopDone(error_t err) {
    post configure_engine();
  }

  event void cuNetNetworkAMSend.sendDone(message_t *msg, error_t error) {
    sendDone(2, F_APPLICATION, msg, error);
  }

  event message_t* cuNetNetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return receive(2, F_APPLICATION, msg, payload, len);
  }

  event message_t* cuNetNetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return snoop(2, F_APPLICATION, msg, payload, len);
  }

  event void cuNetNetworkStatus.status(uint8_t layer, uint8_t status_flag) {
    return status(2, F_APPLICATION, layer, status_flag);
  }

  command error_t cuNetMacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return AMSend_send(2, F_MAC, addr, msg, len);
  }

  command error_t cuNetMacAMSend.cancel(message_t* msg) {
    return AMSend_cancel(2, F_MAC, msg);
  }

  command uint8_t cuNetMacAMSend.maxPayloadLength() {
    return AMSend_maxPayloadLength(2, F_MAC);
  }

  command void* cuNetMacAMSend.getPayload(message_t* msg, uint8_t len) {
    return AMSend_getPayload(2, F_MAC, msg, len);
  }

  command am_addr_t cuNetMacAMPacket.address() {
    return AMPacket_address(2, F_MAC);
  }

  command am_addr_t cuNetMacAMPacket.destination(message_t* msg) {
    return AMPacket_destination(2, F_MAC, msg);
  }

  command am_addr_t cuNetMacAMPacket.source(message_t* msg) {
    return AMPacket_source(2, F_MAC, msg);
  }
  command void cuNetMacAMPacket.setDestination(message_t* msg, am_addr_t addr) {
    return AMPacket_setDestination(2, F_MAC, msg, addr);
  }

  command void cuNetMacAMPacket.setSource(message_t* msg, am_addr_t addr) {
    return AMPacket_setSource(2, F_MAC, msg, addr);
  }
  command bool cuNetMacAMPacket.isForMe(message_t* msg) {
    return AMPacket_isForMe(2, F_MAC, msg);
  }

  command am_id_t cuNetMacAMPacket.type(message_t* msg) {
    return AMPacket_type(2, F_MAC, msg);
  }

  command void cuNetMacAMPacket.setType(message_t* msg, am_id_t t) {
    return AMPacket_setType(2, F_MAC, msg, t);
  }

  command am_group_t cuNetMacAMPacket.group(message_t* msg) {
    return AMPacket_group(2, F_MAC, msg);
  }

  command void cuNetMacAMPacket.setGroup(message_t* msg, am_group_t grp) {
    return AMPacket_setGroup(2, F_MAC, msg, grp);
  }
  command am_group_t cuNetMacAMPacket.localGroup() {
    return AMPacket_localGroup(2, F_MAC);
  }

  command void cuNetMacPacket.clear(message_t* msg) {
    return Packet_clear(2, F_MAC, msg);
  }

  command uint8_t cuNetMacPacket.payloadLength(message_t* msg) {
    return Packet_payloadLength(2, F_MAC, msg);
  }

  command void cuNetMacPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return Packet_setPayloadLength(2, F_MAC, msg, len);
  }

  command uint8_t cuNetMacPacket.maxPayloadLength() {
    return Packet_maxPayloadLength(2, F_MAC);
  }

  command void* cuNetMacPacket.getPayload(message_t* msg, uint8_t len) {
    return Packet_getPayload(2, F_MAC, msg, len);
  }

  async command error_t cuNetMacPacketAcknowledgements.requestAck( message_t* msg ) {
    return PacketAcknowledgements_requestAck(2, F_MAC, msg);
  }

  async command error_t cuNetMacPacketAcknowledgements.noAck( message_t* msg ) {
    return PacketAcknowledgements_noAck(2, F_MAC, msg);
  }

  async command bool cuNetMacPacketAcknowledgements.wasAcked(message_t* msg) {
    return PacketAcknowledgements_wasAcked(2, F_MAC, msg);
  }

  event void nullNetControl.startDone(error_t err) {
    post configure_engine();
  }

  event void nullNetControl.stopDone(error_t err) {
    post configure_engine();
  }

  event void nullNetNetworkAMSend.sendDone(message_t *msg, error_t error) {
    sendDone(6, F_APPLICATION, msg, error);
  }

  event message_t* nullNetNetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return receive(6, F_APPLICATION, msg, payload, len);
  }

  event message_t* nullNetNetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return snoop(6, F_APPLICATION, msg, payload, len);
  }

  event void nullNetNetworkStatus.status(uint8_t layer, uint8_t status_flag) {
    return status(6, F_APPLICATION, layer, status_flag);
  }

  command error_t nullNetMacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    return AMSend_send(6, F_MAC, addr, msg, len);
  }

  command error_t nullNetMacAMSend.cancel(message_t* msg) {
    return AMSend_cancel(6, F_MAC, msg);
  }

  command uint8_t nullNetMacAMSend.maxPayloadLength() {
    return AMSend_maxPayloadLength(6, F_MAC);
  }

  command void* nullNetMacAMSend.getPayload(message_t* msg, uint8_t len) {
    return AMSend_getPayload(6, F_MAC, msg, len);
  }

  command am_addr_t nullNetMacAMPacket.address() {
    return AMPacket_address(6, F_MAC);
  }

  command am_addr_t nullNetMacAMPacket.destination(message_t* msg) {
    return AMPacket_destination(6, F_MAC, msg);
  }

  command am_addr_t nullNetMacAMPacket.source(message_t* msg) {
    return AMPacket_source(6, F_MAC, msg);
  }
  command void nullNetMacAMPacket.setDestination(message_t* msg, am_addr_t addr) {
    return AMPacket_setDestination(6, F_MAC, msg, addr);
  }

  command void nullNetMacAMPacket.setSource(message_t* msg, am_addr_t addr) {
    return AMPacket_setSource(6, F_MAC, msg, addr);
  }
  command bool nullNetMacAMPacket.isForMe(message_t* msg) {
    return AMPacket_isForMe(6, F_MAC, msg);
  }

  command am_id_t nullNetMacAMPacket.type(message_t* msg) {
    return AMPacket_type(6, F_MAC, msg);
  }

  command void nullNetMacAMPacket.setType(message_t* msg, am_id_t t) {
    return AMPacket_setType(6, F_MAC, msg, t);
  }

  command am_group_t nullNetMacAMPacket.group(message_t* msg) {
    return AMPacket_group(6, F_MAC, msg);
  }

  command void nullNetMacAMPacket.setGroup(message_t* msg, am_group_t grp) {
    return AMPacket_setGroup(6, F_MAC, msg, grp);
  }
  command am_group_t nullNetMacAMPacket.localGroup() {
    return AMPacket_localGroup(6, F_MAC);
  }

  command void nullNetMacPacket.clear(message_t* msg) {
    return Packet_clear(6, F_MAC, msg);
  }

  command uint8_t nullNetMacPacket.payloadLength(message_t* msg) {
    return Packet_payloadLength(6, F_MAC, msg);
  }

  command void nullNetMacPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return Packet_setPayloadLength(6, F_MAC, msg, len);
  }

  command uint8_t nullNetMacPacket.maxPayloadLength() {
    return Packet_maxPayloadLength(6, F_MAC);
  }

  command void* nullNetMacPacket.getPayload(message_t* msg, uint8_t len) {
    return Packet_getPayload(6, F_MAC, msg, len);
  }

  async command error_t nullNetMacPacketAcknowledgements.requestAck( message_t* msg ) {
    return PacketAcknowledgements_requestAck(6, F_MAC, msg);
  }

  async command error_t nullNetMacPacketAcknowledgements.noAck( message_t* msg ) {
    return PacketAcknowledgements_noAck(6, F_MAC, msg);
  }

  async command bool nullNetMacPacketAcknowledgements.wasAcked(message_t* msg) {
    return PacketAcknowledgements_wasAcked(6, F_MAC, msg);
  }

  event void cuMacControl.startDone(error_t err) {
    post configure_engine();
  }

  event void cuMacControl.stopDone(error_t err) {
    post configure_engine();
  }

  event void cuMacMacAMSend.sendDone(message_t *msg, error_t error) {
    sendDone(3, F_NETWORK, msg, error);
  }

  event message_t* cuMacMacReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return receive(3, F_NETWORK, msg, payload, len);
  }

  event message_t* cuMacMacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return snoop(3, F_NETWORK, msg, payload, len);
  }

  event void cuMacMacStatus.status(uint8_t layer, uint8_t status_flag) {
    return status(3, F_NETWORK, layer, status_flag);
  }

  command error_t cuMacRadioConfig.sync() {
    return RadioConfig_sync(3, F_RADIO);
  }

  command uint8_t cuMacRadioConfig.getChannel() {
    return RadioConfig_getChannel(3, F_RADIO);
  }

  command void cuMacRadioConfig.setChannel(uint8_t channel) {
    return RadioConfig_setChannel(3, F_RADIO, channel);
  }

  async command uint16_t cuMacRadioConfig.getShortAddr() {
    return RadioConfig_getShortAddr(3, F_RADIO);
  }

  command void cuMacRadioConfig.setShortAddr(uint16_t address) {
    return RadioConfig_setShortAddr(3, F_RADIO, address);
  }

  async command uint16_t cuMacRadioConfig.getPanAddr() {
    return RadioConfig_getPanAddr(3, F_RADIO);
  }

  command void cuMacRadioConfig.setPanAddr(uint16_t address) {
    return RadioConfig_setPanAddr(3, F_RADIO, address);
  }

  command void cuMacRadioConfig.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
    return RadioConfig_setAddressRecognition(3, F_RADIO, enableAddressRecognition, useHwAddressRecognition);
  }

  async command bool cuMacRadioConfig.isAddressRecognitionEnabled() {
    return RadioConfig_isAddressRecognitionEnabled(3, F_RADIO);
  }

  async command bool cuMacRadioConfig.isHwAddressRecognitionDefault() {
    return RadioConfig_isHwAddressRecognitionDefault(3, F_RADIO);
  }

  command void cuMacRadioConfig.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
    return RadioConfig_setAutoAck(3, F_RADIO, enableAutoAck, hwAutoAck);
  }

  async command bool cuMacRadioConfig.isAutoAckEnabled() {
    return RadioConfig_isAutoAckEnabled(3, F_RADIO);
  }

  async command bool cuMacRadioConfig.isHwAutoAckDefault() {
    return RadioConfig_isHwAutoAckDefault(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.startVReg() {
    return RadioPower_startVReg(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.stopVReg() {
    return RadioPower_stopVReg(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.startOscillator() {
    return RadioPower_startOscillator(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.stopOscillator() {
    return RadioPower_stopOscillator(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.rxOn() {
    return RadioPower_rxOn(3, F_RADIO);
  }

  async command error_t cuMacRadioPower.rfOff() {
    return RadioPower_rfOff(3, F_RADIO);
  }

  command error_t cuMacReadRssi.read() {
    return ReadRssi_read(3, F_RADIO);
  }

  async command error_t cuMacRadioResource.request() {
    return RadioResource_request(3, F_RADIO);
  }

  async command error_t cuMacRadioResource.immediateRequest() {
    return RadioResource_immediateRequest(3, F_RADIO);
  }

  async command error_t cuMacRadioResource.release() {
    return RadioResource_release(3, F_RADIO);
  }

  async command error_t cuMacRadioResource.isOwner() {
    return RadioResource_isOwner(3, F_RADIO);
  }

  command error_t cuMacRadioControl.start() {
    return RadioControl_start(3, F_RADIO);
  }

  command error_t cuMacRadioControl.stop() {
    return RadioControl_stop(3, F_RADIO);
  }

  async command void cuMacRadioTransmit.cancel(message_t *msg) {
    return RadioTransmit_cancel(3, F_RADIO, msg);
  }

  async command error_t cuMacRadioTransmit.load(message_t* msg) {
    return RadioTransmit_load(3, F_RADIO, msg);
  }

  async command error_t cuMacRadioTransmit.send(message_t* msg, bool useCca) {
    return RadioTransmit_send(3, F_RADIO, msg, useCca);
  }

  async command bool cuMacPacketIndicator.isReceiving() {
    return PacketIndicator_isReceiving(3, F_RADIO);
  }

  async command bool cuMacEnergyIndicator.isReceiving() {
    return EnergyIndicator_isReceiving(3, F_RADIO);
  }

  async command bool cuMacByteIndicator.isReceiving() {
    return ByteIndicator_isReceiving(3, F_RADIO);
  }

  event void csmacaMacControl.startDone(error_t err) {
    post configure_engine();
  }

  event void csmacaMacControl.stopDone(error_t err) {
    post configure_engine();
  }

  event void csmacaMacMacAMSend.sendDone(message_t *msg, error_t error) {
    sendDone(7, F_NETWORK, msg, error);
  }

  event message_t* csmacaMacMacReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return receive(7, F_NETWORK, msg, payload, len);
  }

  event message_t* csmacaMacMacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return snoop(7, F_NETWORK, msg, payload, len);
  }

  event void csmacaMacMacStatus.status(uint8_t layer, uint8_t status_flag) {
    return status(7, F_NETWORK, layer, status_flag);
  }

  command error_t csmacaMacRadioConfig.sync() {
    return RadioConfig_sync(7, F_RADIO);
  }

  command uint8_t csmacaMacRadioConfig.getChannel() {
    return RadioConfig_getChannel(7, F_RADIO);
  }

  command void csmacaMacRadioConfig.setChannel(uint8_t channel) {
    return RadioConfig_setChannel(7, F_RADIO, channel);
  }

  async command uint16_t csmacaMacRadioConfig.getShortAddr() {
    return RadioConfig_getShortAddr(7, F_RADIO);
  }

  command void csmacaMacRadioConfig.setShortAddr(uint16_t address) {
    return RadioConfig_setShortAddr(7, F_RADIO, address);
  }

  async command uint16_t csmacaMacRadioConfig.getPanAddr() {
    return RadioConfig_getPanAddr(7, F_RADIO);
  }

  command void csmacaMacRadioConfig.setPanAddr(uint16_t address) {
    return RadioConfig_setPanAddr(7, F_RADIO, address);
  }

  command void csmacaMacRadioConfig.setAddressRecognition(bool enableAddressRecognition, bool useHwAddressRecognition) {
    return RadioConfig_setAddressRecognition(7, F_RADIO, enableAddressRecognition, useHwAddressRecognition);
  }

  async command bool csmacaMacRadioConfig.isAddressRecognitionEnabled() {
    return RadioConfig_isAddressRecognitionEnabled(7, F_RADIO);
  }

  async command bool csmacaMacRadioConfig.isHwAddressRecognitionDefault() {
    return RadioConfig_isHwAddressRecognitionDefault(7, F_RADIO);
  }

  command void csmacaMacRadioConfig.setAutoAck(bool enableAutoAck, bool hwAutoAck) {
    return RadioConfig_setAutoAck(7, F_RADIO, enableAutoAck, hwAutoAck);
  }

  async command bool csmacaMacRadioConfig.isAutoAckEnabled() {
    return RadioConfig_isAutoAckEnabled(7, F_RADIO);
  }

  async command bool csmacaMacRadioConfig.isHwAutoAckDefault() {
    return RadioConfig_isHwAutoAckDefault(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.startVReg() {
    return RadioPower_startVReg(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.stopVReg() {
    return RadioPower_stopVReg(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.startOscillator() {
    return RadioPower_startOscillator(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.stopOscillator() {
    return RadioPower_stopOscillator(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.rxOn() {
    return RadioPower_rxOn(7, F_RADIO);
  }

  async command error_t csmacaMacRadioPower.rfOff() {
    return RadioPower_rfOff(7, F_RADIO);
  }

  command error_t csmacaMacReadRssi.read() {
    return ReadRssi_read(7, F_RADIO);
  }

  async command error_t csmacaMacRadioResource.request() {
    return RadioResource_request(7, F_RADIO);
  }

  async command error_t csmacaMacRadioResource.immediateRequest() {
    return RadioResource_immediateRequest(7, F_RADIO);
  }

  async command error_t csmacaMacRadioResource.release() {
    return RadioResource_release(7, F_RADIO);
  }

  async command error_t csmacaMacRadioResource.isOwner() {
    return RadioResource_isOwner(7, F_RADIO);
  }

  command error_t csmacaMacRadioControl.start() {
    return RadioControl_start(7, F_RADIO);
  }

  command error_t csmacaMacRadioControl.stop() {
    return RadioControl_stop(7, F_RADIO);
  }

  async command void csmacaMacRadioTransmit.cancel(message_t *msg) {
    return RadioTransmit_cancel(7, F_RADIO, msg);
  }

  async command error_t csmacaMacRadioTransmit.load(message_t* msg) {
    return RadioTransmit_load(7, F_RADIO, msg);
  }

  async command error_t csmacaMacRadioTransmit.send(message_t* msg, bool useCca) {
    return RadioTransmit_send(7, F_RADIO, msg, useCca);
  }

  async command bool csmacaMacPacketIndicator.isReceiving() {
    return PacketIndicator_isReceiving(7, F_RADIO);
  }

  async command bool csmacaMacEnergyIndicator.isReceiving() {
    return EnergyIndicator_isReceiving(7, F_RADIO);
  }

  async command bool csmacaMacByteIndicator.isReceiving() {
    return ByteIndicator_isReceiving(7, F_RADIO);
  }

  event void cc2420RadioControl.startDone(error_t err) {
    post configure_engine();
  }

  event void cc2420RadioControl.stopDone(error_t err) {
    post configure_engine();
  }

  event message_t* cc2420RadioRadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return receive(4, F_MAC, msg, payload, len);
  }

  event void cc2420RadioRadioStatus.status(uint8_t layer, uint8_t status_flag) {
    return status(4, F_MAC, layer, status_flag);
  }

  event void cc2420RadioRadioConfig.syncDone(error_t error) {
    return syncDone(4, F_MAC, error);
  }

  async event void cc2420RadioRadioPower.startVRegDone() {
    return startVRegDone(4, F_MAC);
  }

  async event void cc2420RadioRadioPower.startOscillatorDone() {
    return startOscillatorDone(4, F_MAC);
  }

  event void cc2420RadioReadRssi.readDone(error_t error, uint16_t rssi) {
    return readRssiDone(4, F_MAC, error, rssi);
  }

  event void cc2420RadioRadioResource.granted() {
    return granted(4, F_MAC);
  }

  async event void cc2420RadioRadioTransmit.loadDone(message_t* msg, error_t error) {
    return transmitLoadDone(4, F_MAC, msg, error);
  }

  async event void cc2420RadioRadioTransmit.sendDone(message_t *msg, error_t error) {
    return transmitSendDone(4, F_MAC, msg, error);
  }

  event void cc2420RadioRadioControl.startDone(error_t error) {
    return radioControlStartDone(4, F_MAC, error);
  }

  event void cc2420RadioRadioControl.stopDone(error_t error) {
    return radioControlStopDone(4, F_MAC, error);
  }


}
