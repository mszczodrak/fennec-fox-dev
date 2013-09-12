configuration EnergyC {
provides interface SimpleStart;
}

implementation {

components EnergyP;
SimpleStart = EnergyP;

components capeSolarCellC as EnergySrc;
EnergyP.EnergySrcCtrl -> EnergySrc;

}
