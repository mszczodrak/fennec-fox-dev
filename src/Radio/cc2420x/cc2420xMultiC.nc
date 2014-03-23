configuration cc2420xMultiC {
provides interface SplitControl[process_t process_id];
uses interface cc2420xParams[process_t process_id];
}

implementation {

components cc2420xMultiP;
SplitControl = cc2420xMultiP;
cc2420xParams = cc2420xMultiP;


}

