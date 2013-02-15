configuration ProtocolStackC {
provides interface Mgmt;
}

implementation {

components ProtocolStackP;
Mgmt = ProtocolStackP.Mgmt;

components FennecEngineC;
ProtocolStackP.ModuleCtrl -> FennecEngineC;


}
