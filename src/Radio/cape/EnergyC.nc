configuration EnergyC {
provides interface SimpleStart;
provides interface SimDynamicEnergy;
}

implementation {

components EnergyP;
SimpleStart = EnergyP;
SimDynamicEnergy = EnergyP;

components SolarCellC as EnergySrc;
EnergyP.SplitControl -> EnergySrc;

EnergySrc.SimDynamicEnergy -> EnergyP;


}
