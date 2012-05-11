generic module BitVectorSafeC(uint16_t max_bits)
{
  provides interface Init;
  provides interface BitVectorSafe;
}
implementation
{
  typedef uint8_t int_type;

  enum
  {
    ELEMENT_SIZE = 8*sizeof(int_type),
    ARRAY_SIZE = (max_bits + ELEMENT_SIZE - 1) / ELEMENT_SIZE,
  };

  int_type m_bits[ ARRAY_SIZE ];

  uint16_t getIndex(uint16_t bitnum)
  {
    return bitnum / ELEMENT_SIZE;
  }

  uint16_t getMask(uint16_t bitnum)
  {
    return 1 << (bitnum % ELEMENT_SIZE);
  }

  command error_t Init.init()
  {
    call BitVectorSafe.clearAll();
    return SUCCESS;
  }

  async command void BitVectorSafe.clearAll()
  {
    memset(m_bits, 0, sizeof(m_bits));
  }

  async command void BitVectorSafe.setAll()
  {
    memset(m_bits, 255, sizeof(m_bits));
  }

  async command bool BitVectorSafe.get(uint16_t bitnum)
  {
    atomic {
      if (bitnum < max_bits) 
        return (m_bits[getIndex(bitnum)] & getMask(bitnum)) ? TRUE : FALSE; }
  }

  async command void BitVectorSafe.set(uint16_t bitnum)
  {
    dbg("Bit", "Bit size is %d\n", ARRAY_SIZE);
    atomic {if (bitnum < max_bits) m_bits[getIndex(bitnum)] |= getMask(bitnum);}
  }

  async command void BitVectorSafe.clear(uint16_t bitnum)
  {
    atomic {if (bitnum < max_bits) m_bits[getIndex(bitnum)] &= ~getMask(bitnum);}
  }

  async command void BitVectorSafe.toggle(uint16_t bitnum)
  {
    atomic {if (bitnum < max_bits) m_bits[getIndex(bitnum)] ^= getMask(bitnum);}
  }

//  async command void BitVectorSafe.assign(uint16_t bitnum, bool value)
//  {
//    if(value)
//      call BitVectorSafe.set(bitnum);
//    else
//      call BitVectorSafe.clear(bitnum);
//  }

  async command uint16_t BitVectorSafe.size()
  {
    return max_bits;
  }

  async command void BitVectorSafe.setIntValue(uint32_t value)
  {
    atomic {
      memset(m_bits, 0, sizeof(m_bits));

      if (ARRAY_SIZE > 3)  m_bits[3] = value >> 24;
    
      if (ARRAY_SIZE > 2)  m_bits[2] = (value << 8) >> 24;
    
      if (ARRAY_SIZE > 1)  m_bits[1] = (value << 16) >> 24;
    
      if (ARRAY_SIZE > 0)  m_bits[0] = (value << 24) >> 24; 
    }
  }

  async command uint32_t BitVectorSafe.getIntValue()
  {
    atomic {
      uint32_t r = 0;

      if (ARRAY_SIZE > 3)  r |= m_bits[3] << 24; 
    
      if (ARRAY_SIZE > 2)  r |= m_bits[2] << 16;
    
      if (ARRAY_SIZE > 1)  r |= m_bits[1] << 8;
    
      if (ARRAY_SIZE > 0)  r |= m_bits[0];
    
      return r;
    }
  }
}

