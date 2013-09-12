configuration SolarCellC {

provides interface SplitControl;
provides interface SolarCell;

uses interface SimDynamicEnergy;
}

implementation {

components SolarCellP;
SplitControl = SolarCellP;
SolarCell = SolarCellP;
SimDynamicEnergy = SolarCellP;

//#ifdef TOSSIM
//components IrradianceModelC as IrradianceC;
//#else
components IrradianceTraceC as IrradianceC;
//#endif

SolarCellP.Irradiance -> IrradianceC;
}
