#!/usr/bin/python

from socket import *             # Imports socket module
from struct import *

# sensor input pkt is
# int node_id, int sensor_id, double value

host="127.0.0.1"            # Set the server address to variable host
port=9003               # Sets the variable port to 4444
s=socket(AF_INET, SOCK_STREAM)      # Creates a socket
s.connect((host,port))          # Connect to server address
msg=s.recv(1024)            # Receives data upto 1024 bytes and stores in variables msg
print msg		# Should say something like "Welcome to Testbed Sensor Input"

m = pack('!HHL', 1, 2, 3)

s.send(a)

#print "Message from server : " + msg
 
s.close()                            # Closes the socket 
# End of code
