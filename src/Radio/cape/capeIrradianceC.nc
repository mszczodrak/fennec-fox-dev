configuration capeIrradianceC;
provides interface Irradiance;
}
implementation {
components IrradianceModelC;
Irradiance = IrradianceModelC;
}
