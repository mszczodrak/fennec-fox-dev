configuration capeSolarCellC {
provides interface SplitControl;
provides interface SolarCell;
}

implementation {

components SolarCellP;
SplitControl = SolarCellP;
SolarCell = SolarCellP;

components IrradianceModelC as Model;
SolarCellP.IrradianceModel -> Model;

}
