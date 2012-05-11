/*
 * Application: 
 * Author: 
 * Date: 
 */

generic configuration BridgeAppC() {
  provides interface Mgmt;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components new BridgeAppP();
  Mgmt = BridgeAppP;
  NetworkCall = BridgeAppP;
  NetworkSignal = BridgeAppP;

  components LedsC;
  BridgeAppP.Leds -> LedsC;

  components RawSerialC;
  BridgeAppP.Serial -> RawSerialC;
  BridgeAppP.SerialControl -> RawSerialC;

}
