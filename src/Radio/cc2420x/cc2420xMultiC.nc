configuration cc2420xMultiC {
provides interface SplitControl[process_t process_id];


}

implementation {

components cc2420xMultiP;
SplitControl = cc2420xMultiP;


}

