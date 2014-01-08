configuration SolarCellSpecC {
provides interface SolarCell;
}

implementation {
components SolarCellSpecP;
SolarCell = SolarCellSpecP;
}
