interface BitVectorSafe
{
  /**
   * Clear all bits in the vector.
   */
  async command void clearAll();

  /**
   * Set all bits in the vector.
   */
  async command void setAll();

  /**
   * Read a bit from the vector.
   * @param bitnum Bit to read.
   * @return Bit value.
   */
  async command bool get(uint16_t bitnum);

  /**
   * Set a bit in the vector.
   * @param bitnum Bit to set.
   */
  async command void set(uint16_t bitnum);

  /**
   * Set a bit in the vector.
   * @param bitnum Bit to clear.
   */
  async command void clear(uint16_t bitnum);

  /**
   * Toggle a bit in the vector.
   * @param bitnum Bit to toggle.
   */
  async command void toggle(uint16_t bitnum);

  /**
   * Write a bit in the vector.
   * @param bitnum Bit to clear.
   * @param value New bit value.
   */

//  async command void assign(uint16_t bitnum, bool value);
// is there actually any point in this function
// could a user test value before use set a bit to 1 or 0 
// or this function implements a common case

  /**
   * Return bit vector length.
   * @return Bit vector length.
   */
  async command uint16_t size();

  /**
   * Set bits in the vector based on uint32_t value.
   * @param value Integer used to set bits in the vector.
   */
  async command void setIntValue(uint32_t value);

  /*
   * Return uint32_t value of the bit vector.
   * @return Integer value.
   */
  async command uint32_t getIntValue();
}

