

configuration IrradianceModelC {
provides interface IrradianceModel;
}

implementation {

components IrradianceModelP;
IrradianceModel = IrradianceModelP;

}
