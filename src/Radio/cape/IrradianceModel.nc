interface IrradianceModel {
command error_t startHarvesting();
command error_t stopHarvesting();
event void harvestedW(double watt);
event void harvestedJ(double joule);
}
