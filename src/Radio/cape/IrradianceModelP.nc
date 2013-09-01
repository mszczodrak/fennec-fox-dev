

module IrradianceModelP {
provides interface IrradianceModel;
uses interface Timer<TMilli>;
}

implementation {

command error_t IrradianceModel.startHarvesting() {
	return SUCCESS;
}

command error_t IrradianceModel.stopHarvesting() {
	return SUCCESS;
}


event void Timer.fired() {



}


}
