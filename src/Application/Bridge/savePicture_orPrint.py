#!/usr/bin/python

import serial
import time

class Mote:

  def __init__(self):
    self.dev = '/dev/ttyUSB1'
#    self.bound = 115200 
#    self.bound = 230400  
#    self.bound = 460800  
    self.bound = 921600 
    self.timeout = 1
    self.buf = []
    self.str_buf = []
    self.s = serial.Serial(self.dev, self.bound, timeout = self.timeout)
    self.pictureFileName = "/tmp/pic"
    self.size_x = 320
    self.size_y = 240
    self.busy = 0
    self.counter = 0

    self.run()
    self.timestamp = 0.0


  def run(self):
  
    while 1:
      c = self.s.read()
      if len(c) > 0:
        print 'Serial:getByte: 0x%02x' % ord(c)
        if self.busy == 0:
          self.busy = 1
          self.timestamp = time.time()
        self.counter = self.counter + 1
        self.buf.append(int(ord(c)))
	if self.counter <= 200:
	  self.str_buf.append(c)
      else:
        print 'nothing'
        if self.busy == 1:
          print 'Sending time %f' % (time.time() - self.timestamp)
          print 'Received %d bytes' % (self.counter)
          if self.counter > 200:
            self.process()
	  else :
	    for c in self.str_buf:
              print c,
            print
          self.busy = 0
          self.counter = 0



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
    print "Processed"




if __name__ == "__main__":
  s = Mote()

