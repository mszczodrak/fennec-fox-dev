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

components IrradianceModelC as Model;
SolarCellP.IrradianceModel -> Model;

}
