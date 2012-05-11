#!/usr/bin/python

import serial
import time

class Mote:

  def __init__(self):
    self.dev = '/dev/ttyUSB1'
    self.bound = 115200 
#    self.bound = 230400  
    self.timeout = 1
    self.buf = []
    self.s = serial.Serial(self.dev, self.bound, timeout = self.timeout)
    self.pictureFileName = "/tmp/pic"
    self.size_x = 320
    self.size_y = 240
    self.busy = 0

    self.run()


  def run(self):
  
    while 1:
      c = self.s.read()
      if len(c) > 0:
        print 'Serial:getByte: 0x%02x' % ord(c)
        self.busy = 1
        self.buf.append(int(ord(c)))
      else:
        print 'nothing'
        if self.busy == 1:
          self.busy = 0
          self.process()



  def process(self):
    fpic = open("%s_%s.ppm"%(self.pictureFileName, time.ctime().replace(' ','_')),"w");

    header = "P2\r\n" + str(self.size_x) + " " + str(self.size_y) + "\r\n" + "255\r\n"

    fpic.write(header)

    lc = 0

    for byte in self.buf:
      lc = lc + 1
      fpic.write("%d " % byte )
      if not(lc % self.size_x):
        fpic.write("\r\n");
      
    fpic.close()
    self.buf = []
    print "Processed %d bytes"%(lc)




if __name__ == "__main__":
  s = Mote()

