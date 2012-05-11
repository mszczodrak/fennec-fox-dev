#!/usr/bin/python

import serial
import time
import sys
import os
import httplib
from tinyos.message import MoteIF
from threading import Thread
import threading


goali_server = "web.sld.cs.columbia.edu"
request = "/demo_sense_environment/default/call/run/insert?"

class ReportEnv(Thread):
  def __init__(self, buf):
    Thread.__init__(self)
    self.buf = buf

  def run(self):
    n = int(self.buf[0]) * 255 + int(self.buf[1])
    c = int(self.buf[2]) * 255 + int(self.buf[3])
    t = int(self.buf[4]) * 255 + int(self.buf[5])
    h = int(self.buf[6]) * 255 + int(self.buf[7])
    l = int(self.buf[8]) * 255 + int(self.buf[9])

    print "\nCounter: %d\nTemp %d \nHum %d\nLight %d\n" % (c, t, h, l)

    self.conn = httplib.HTTPConnection(goali_server)
    url_request = "%snode=%d&counter=%d&temp=%d&hum=%d&light=%d"%(request,
                n, c, t, h, l)
    print url_request
    self.conn.request("GET", url_request)
    r1 = self.conn.getresponse()

    sys.exit()

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
    self.max_counter = 200
    self.min_counter = 4

    self.run()
    self.timestamp = 0.0


  def run(self):
  
    while 1:
      c = self.s.read()

      if len(c) > 0:
        #print 'Serial:getByte: 0x%02x' % ord(c)
        if self.busy == 0:
          self.busy = 1
          self.timestamp = time.time()
        self.counter = self.counter + 1
        self.buf.append(int(ord(c)))
	if self.counter <= self.max_counter:
	  self.str_buf.append(c)
      else:
        #print 'nothing'
        if self.busy == 1:
          if self.counter > self.min_counter:
            #print 'Sending time %f' % (time.time() - self.timestamp)
            #print 'Received %d bytes' % (self.counter)
            self.process()
	  else :
            sys.stdout.write("%s"%(''.join(self.str_buf)))

          self.buf = []
          self.str_buf = []
          self.busy = 0
          self.counter = 0



  def process(self):
    print "Processing"
    print len(self.buf)

    if len(self.buf) > 20 and len(self.buf) < 70000:
      self.buf = []
      return

    if len(self.buf) == 10:
      t = ReportEnv(self.buf[:])
      t.start()

    else:
      fpic = open("%s.ppm"%(self.pictureFileName), "w")
      header = "P2\r\n" + str(self.size_x) + " " + str(self.size_y) + "\r\n" + "255\r\n"
      fpic.write(header)
      lc = 0
      for byte in self.buf:
        lc = lc + 1
        fpic.write("%d " % byte )
        if not(lc % self.size_x):
          fpic.write("\r\n");
      fpic.close()
      os.system("convert %s.ppm %s.jpg"%(self.pictureFileName, self.pictureFileName))
      os.system("scp %s.jpg msz@clic.cs.columbia.edu:~/html/demo/picture.jpg"%(self.pictureFileName))

    self.buf = []
    print "Processed"


if __name__ == "__main__":
  s = Mote()

