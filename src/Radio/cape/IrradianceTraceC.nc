configuration IrradianceTraceC {
provides interface Irradiance;
}

implementation {

components IrradianceTraceP;
Irradiance = IrradianceTraceP;

components new TimerMilliC();
IrradianceTraceP.Timer -> TimerMilliC;

}

