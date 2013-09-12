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
//components capeIrradianceC as IrradianceC;
//#else
components SolarCellSpecC as SolarC;
components IrradianceTraceC as IrradianceC;
//#endif

SolarCellP.Irradiance -> IrradianceC;
SolarCellP.SubSolarCell -> SolarC;
}
