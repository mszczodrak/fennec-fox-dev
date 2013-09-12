module SolarCellModelP {
provides interface SolarCell;
}

implementation {

command double SolarCell.getEfficiency() {
	return sim_seh_solar_cell_efficiency();
}

command double SolarCell.getArea() {
	return sim_seh_solar_cell_size();
}

}
