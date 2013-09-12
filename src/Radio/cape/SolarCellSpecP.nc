#include "solar_cell.h"

module SolarCellSpecP {
provides interface SolarCell;
}

implementation {

command double SolarCell.getEfficiency() {
        return SIM_CELL_EFFICIENCY;
}

command double SolarCell.getArea() {
        return SIM_CELL_SIZE;
}


}
