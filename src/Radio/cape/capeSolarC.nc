configuration capeSolarC {
provides interface SolarCell;
}
implementation {
components SolarCellModelC;
SolarCell = SolarCellModelC;
}
