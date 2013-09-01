

configuration IrradianceModelC {
provides interface IrradianceModel;
}

implementation {

components IrradianceModelP;
IrradianceModel = IrradianceModelP;

components new TimerMilliC();
IrradianceModelP.Timer -> TimerMilliC;

}
