module ParametersCtpP @safe() {

  provides interface ParametersCtp;
}

implementation {

  am_addr_t 	current_root_addr;

  command void ParametersCtp.set_root_addr(am_addr_t new_root_addr) {
    current_root_addr = new_root_addr;
  }

  command am_addr_t ParametersCtp.get_root_addr() {
    return current_root_addr;
  }

}
