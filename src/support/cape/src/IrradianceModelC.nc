

configuration IrradianceModelC {
provides interface Irradiance;
}

implementation {

components IrradianceModelP;
Irradiance = IrradianceModelP;

}
