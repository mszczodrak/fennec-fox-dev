#!/usr/bin/python

import serial

class Mote:

  def __init__(self):
    self.dev = '/dev/ttyUSB1'
    self.bound = 230400 #115200
    self.timeout = 1
    self.buf = []
    self.s = serial.Serial(self.dev, self.bound, timeout = self.timeout)

    self.busy = 0

    self.run()


  def run(self):
  
    while 1:
      sin = self.s.read(1000)
      if len(sin) > 0:
        self.busy = 1
        self.buf.append(sin)
        print sin
      else:
          if self.busy == 1:
            self.busy = 0
            self.process()
            print "Processed"



  def process(self):

    self.buf = []




if __name__ == "__main__":
  s = Mote()

