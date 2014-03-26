generic configuration cc2420xCollisionLayerC() {

provides interface RadioSend;
provides interface RadioReceive;

uses interface RadioSend as SubSend;
uses interface RadioReceive as SubReceive;
uses interface RadioAlarm;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface cc2420xParams;

}

implementation {

components new cc2420xCollisionLayerP();
RadioSend = cc2420xCollisionLayerP.RadioSend;
RadioReceive = cc2420xCollisionLayerP.RadioReceive;
SubSend = cc2420xCollisionLayerP.SubSend;
SubReceive = cc2420xCollisionLayerP.SubReceive;
RadioAlarm = cc2420xCollisionLayerP.RadioAlarm;
RandomCollisionConfig = cc2420xCollisionLayerP.RandomCollisionConfig;
SlottedCollisionConfig = cc2420xCollisionLayerP.SlottedCollisionConfig;
cc2420xParams = cc2420xCollisionLayerP.cc2420xParams;

/* wire to SlottedCollisionLayer */

components new SlottedCollisionLayerC();
cc2420xCollisionLayerP.SlottedRadioSend -> SlottedCollisionLayerC.RadioSend;
cc2420xCollisionLayerP.SlottedRadioReceive -> SlottedCollisionLayerC.RadioReceive;

SlottedCollisionLayerC.SubSend -> cc2420xCollisionLayerP.SlottedSubSend;
SlottedCollisionLayerC.SubReceive -> cc2420xCollisionLayerP.SlottedSubReceive;
SlottedCollisionLayerC.RadioAlarm -> cc2420xCollisionLayerP.SlottedRadioAlarm;
SlottedCollisionLayerC.Config -> cc2420xCollisionLayerP.SlottedConfig;

/* wire to RandomCollisionLayer */

components new RandomCollisionLayerC();
cc2420xCollisionLayerP.RandomRadioSend -> RandomCollisionLayerC.RadioSend;
cc2420xCollisionLayerP.RandomRadioReceive -> RandomCollisionLayerC.RadioReceive;

RandomCollisionLayerC.SubSend -> cc2420xCollisionLayerP.RandomSubSend;
RandomCollisionLayerC.SubReceive -> cc2420xCollisionLayerP.RandomSubReceive;
RandomCollisionLayerC.RadioAlarm -> cc2420xCollisionLayerP.RandomRadioAlarm;
RandomCollisionLayerC.Config -> cc2420xCollisionLayerP.RandomConfig;

}
