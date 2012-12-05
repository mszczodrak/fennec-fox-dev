/*
 *  ADC Phidget application module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Application: ADC Phidget Application Module
 * Author: Marcin Szczodrak
 * Author: Dhananjay Palshikar
 * Date: 12/05/2012
 */

#include <Fennec.h>
#include "TestPhidgetAdcApp.h"

module TestPhidgetAdcAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface TestPhidgetAdcAppParams ;
  uses interface SensorCtrl;
  uses interface Read<uint16_t> as Raw;
  uses interface Read<bool> as Occurence;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
  

  uses interface AMSend as SerialAMSend;
  uses interface AMPacket as SerialAMPacket;
  uses interface Packet as SerialPacket;
  uses interface Receive as SerialReceive;
  uses interface SplitControl as SerialSplitControl;

  uses interface Timer<TMilli> as Timer;
  uses interface Leds as LedsBlink;
}

implementation {

  bool netEnable = MoteToSerial;
  uint16_t sampleCount = SAMPLE_COUNT_DEFAULT; //samples per packet
  message_t packet_in,  packet_out;
  app_data_t *msg_payload = NULL, *serial_msg_payload = NULL;
  bool sendBusy = FALSE;
  uint16_t packet_size = 0,serial_packet_size  = 0;
  uint16_t dest = 0;

  task void appStartDone(){
    signal Mgmt.startDone(SUCCESS);
  }
	
  void chooseNetwork(bool net){
    netEnable = net;
    call SerialSplitControl.start();
    if (net) { 		/* data to radio */
      dest = call TestPhidgetAdcAppParams.get_dest();
      msg_payload = (app_data_t*) 
		call NetworkAMSend.getPayload(&packet_out,packet_size);
    } else{ 		/* data to serial */
      msg_payload = (app_data_t*) 
		call SerialAMSend.getPayload(&packet_out,packet_size);
    }
    msg_payload->count = 0;
    serial_msg_payload = (app_data_t*) call SerialAMSend.getPayload(&packet_in,packet_size);
    serial_msg_payload->count = 0;
  }


  void initApp(){
    dbg("Application", "Application ADC Test Module starts\n");
    call Timer.startPeriodic(call TestPhidgetAdcAppParams.get_freq() * 2);
    call SensorCtrl.set_rate(call TestPhidgetAdcAppParams.get_freq());
    call SensorCtrl.set_input_channel(call TestPhidgetAdcAppParams.get_inputChannel());
    call SensorCtrl.set_signaling(TRUE); //can be taken as param from Swift
    call SensorCtrl.start();
    netEnable = call TestPhidgetAdcAppParams.get_netEnable();
    packet_size = sizeof(app_data_t) + (sampleCount * sizeof(uint16_t));
    serial_packet_size = sizeof(app_data_t) + ( SERIAL_PACKET_SIZE * sizeof(uint16_t));
    chooseNetwork(netEnable); 
  }

  command error_t Mgmt.start() {
    sampleCount = call TestPhidgetAdcAppParams.get_sampleCount();

    // checking for overflow for packet size
    if(sampleCount > SAMPLE_COUNT_MAX ){ 
      sampleCount =  SAMPLE_COUNT_MAX;
    }
    else{
      initApp();
      post appStartDone();
    }
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }
  
  void sendMessage(uint16_t data) {
    if ((msg_payload == NULL) | (sendBusy == TRUE)) {
      return;
    }  
    msg_payload->data[msg_payload->count++] = data;
    if(msg_payload->count == sampleCount){

      if(netEnable){
        if (call NetworkAMSend.send(dest, &packet_out,packet_size ) != SUCCESS) {
        msg_payload->count = 0;
        }    
        else {
          sendBusy = TRUE;
        }    
      } // netEnable == TRUE
      else{
        if (call SerialAMSend.send(dest, &packet_in,packet_size ) != SUCCESS) {
        }   
        else {
        sendBusy = TRUE;
        }
     } 
    }
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
    sendBusy = FALSE;
    if(error == SUCCESS){
      msg_payload->count = 0;
    }
  }

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    app_data_t *payload_data = (app_data_t*) payload;
    serial_msg_payload->count = 0;
    serial_msg_payload->data[serial_msg_payload->count++] = payload_data->data[0];
    call SerialAMSend.send(dest, &packet_in,serial_packet_size);
    call LedsBlink.led0Toggle(); /*red led*/
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }


  event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
    //uint8_t *serialData = (uint8_t*) payload;
    call LedsBlink.led1Toggle(); //red led
    return msg;
  }

  event void SerialAMSend.sendDone(message_t *msg, error_t error) {
    sendBusy = FALSE;
    if(error == SUCCESS){
      msg_payload->count = 0;
    }
  }
	
  event void Timer.fired() {
    error_t error = call Raw.read();
      if(error == SUCCESS){
    }
  }

  event void Raw.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      /* sends packet if data count equals sampleCount, 
	 else appends data to the buffer */
      sendMessage(data);
    }
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {}
  event void SerialSplitControl.startDone(error_t error) {}
  event void SerialSplitControl.stopDone(error_t errot){}
  event void TestPhidgetAdcAppParams.receive_status(uint16_t status_flag) {}
  event void SensorCtrl.startDone(error_t error){}
  event void SensorCtrl.stopDone(error_t error){}
  event void Occurence.readDone(error_t error, bool data){}

}
