configuration RegistryC {
provides interface SimpleStart;
}

implementation {

components RegistryP;
SimpleStart = RegistryP;

}
