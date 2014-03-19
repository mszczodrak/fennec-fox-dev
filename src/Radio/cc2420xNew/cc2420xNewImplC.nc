configuration cc2420xNewImplC {
provides interface Resource[uint8_t id];
}

implementation {

components new SimpleFcfsArbiterC("cc2420xNew");
Resource = SimpleFcfsArbiterC.Resource;

}
