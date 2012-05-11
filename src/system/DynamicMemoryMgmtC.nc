generic module DynamicMemoryMgmtC(typedef mem_t, uint8_t size) {
  provides interface Memory<mem_t>;
}

implementation {

  uint8_t left = size;
  mem_t* ONE_NOK mem[size];

  command bool Memory.empty() {
    return left == 0;
  }
  command uint8_t Memory.size() {
    return left;
  }
    
  command uint8_t Memory.maxSize() {
    return size;
  }

  command mem_t* Memory.get() {
    if (left) {
      uint8_t i;
      for (i = 0; i < size; i++) {
        if( mem[i] == NULL) {
          mem[i] = (mem_t*) malloc(sizeof(mem_t));
          left--;
          return mem[i];          
        }
      }      
    }
    return NULL;
  }

  command error_t Memory.put(mem_t* newVal) {
    uint8_t i;
    for (i = 0; i < size; i++) {
      if ( mem[i] == newVal) {
        free(mem[i]);
        mem[i] = NULL;
        left++;
        return SUCCESS;
      }
    }
    return FAIL;
  }

  command void Memory.reset() {
    uint16_t i;
    for(i = 0; i < size; i++) {
      free(mem[i]);
      mem[i] = NULL;
    }
    left = size;
  }

}
