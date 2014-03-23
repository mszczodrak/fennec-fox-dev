module cc2420xMultiP {
provides interface RadioReceive[process_t process_id];
uses interface RadioReceive as SubRadioReceive;
}

implementation {

tasklet_async event bool RadioReceive.header(message_t* msg) {

}

tasklet_async event bool RadioReceive.receive(message_t* msg) {

}


}
