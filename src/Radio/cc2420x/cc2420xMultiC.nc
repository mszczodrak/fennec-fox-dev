configuration cc2420xMultiC {
provides interface SplitControl[process_t process_id];
provides interface RadioReceive[process_t process_id];
provides interface RadioSend[process_t process_id];
provides interface RadioState[process_t process_id];

uses interface cc2420xParams[process_t process_id];
uses interface RadioReceive as SubRadioReceive;
uses interface RadioSend as SubRadioSend;
uses interface RadioState as SubRadioState;
uses interface CC2420XDriverConfig;
}

implementation {

components cc2420xMultiP;
SplitControl = cc2420xMultiP;
cc2420xParams = cc2420xMultiP;
CC2420XDriverConfig = cc2420xMultiP;

RadioReceive = cc2420xMultiP.RadioReceive;
SubRadioReceive = cc2420xMultiP.SubRadioReceive;


RadioSend = cc2420xMultiP.RadioSend;
SubRadioSend = cc2420xMultiP.SubRadioSend;

RadioState = cc2420xMultiP.RadioState;
SubRadioState = cc2420xMultiP.SubRadioState;

}

