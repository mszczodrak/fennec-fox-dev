generic configuration cc2420xCollisionLayerC() {

provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;

}

implementation {

components new cc2420xCollisionLayerP();
RadioSend = cc2420xCollisionLayerP;
RadioReceive = cc2420xCollisionLayerP;
SubSend = cc2420xCollisionLayerP;
SubReceive = cc2420xCollisionLayerP'
RadioAlarm = cc2420xCollisionLayerP;
RandomCollisionConfig = cc2420xCollisionLayerP;
SlottedCollisionConfig = cc2420xCollisionLayerP;




}
