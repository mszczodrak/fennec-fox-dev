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
RadioSend = cc2420xCollisionLayerP.RadioSend;
RadioReceive = cc2420xCollisionLayerP.RadioReceive;
SubSend = cc2420xCollisionLayerP.SubSend;
SubReceive = cc2420xCollisionLayerP.SubReceive;
RadioAlarm = cc2420xCollisionLayerP.RadioAlarm;
RandomCollisionConfig = cc2420xCollisionLayerP.RandomCollisionConfig;
SlottedCollisionConfig = cc2420xCollisionLayerP.SlottedCollisionConfig;


/* wire to SlottedCollisionLayer */

components new SlottedCollisionLayerC();
c2420xCollisionLayerP.SlottedRadioSend -> SlottedCollisionLayerC.RadioSend;
c2420xCollisionLayerP.SlottedRadioReceive -> SlottedCollisionLayerC.RadioReceive;

SlottedCollisionLayerC.SubSend -> c2420xCollisionLayerP.SlottedSubSend;
SlottedCollisionLayerC.SubReceive -> c2420xCollisionLayerP.SlottedSubReceive;
SlottedCollisionLayerC.RadioAlarm -> c2420xCollisionLayerP.SlottedRadioAlarm;
SlottedCollisionLayerC.Config -> cc2420xCollisionLayerP.SlottedConfig;

/* wire to RandomCollisionLayer */

components new RandomCollisionLayerC();
c2420xCollisionLayerP.RandomRadioSend -> RandomCollisionLayerC.RadioSend;
c2420xCollisionLayerP.RandomRadioReceive -> RandomCollisionLayerC.RadioReceive;

RandomCollisionLayerC.SubSend -> c2420xCollisionLayerP.RandomSubSend;
RandomCollisionLayerC.SubReceive -> c2420xCollisionLayerP.RandomSubReceive;
RandomCollisionLayerC.RadioAlarm -> c2420xCollisionLayerP.RandomRadioAlarm;
RandomCollisionLayerC.Config -> c2420xCollisionLayerP.RandomConfig;

}
