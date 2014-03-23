configuration cc2420xMultiC {

provides interface RadioReceive[process_t process_id];

}

implementation {

components CC2420XDriverLayerP;
components cc2420xMultiP;

RadioReceive = cc2420xMultiP;
cc2420xMultiP.SubRadioReceive -> CC2420XDriverLayerP.RadioReceive;

}

