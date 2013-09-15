module RegistryP {
provides interface SimpleStart;
}

implementation {

task void start_done() {
	signal SimpleStart.startDone(SUCCESS);
}

command void SimpleStart.start() {
	post start_done();

}

}
