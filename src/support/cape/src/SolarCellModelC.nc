configuration SolarCellModelC {
provides interface SolarCell;
}

implementation {

components SolarCellModelP;
SolarCell = SolarCellModelP;

}
