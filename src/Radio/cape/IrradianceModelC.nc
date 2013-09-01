

module IrradianceModelC {
provides interface IrradianceModel;
}

implementation {

command error_t IrradianceModel.startHarvesting() {
	return SUCCESS;
}

command error_t IrradianceModel.stopHarvesting() {
	return SUCCESS;
}



}
