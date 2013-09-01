interface IrradianceModel {
command error_t startHarvesting();
command error_t stopHarvesting();
event void harvested(uint16_t watt);
}
