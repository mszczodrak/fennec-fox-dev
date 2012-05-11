#!/usr/bin/python
# Author: Marcin Szczodrak
# Constants defined in Fennec.h as Python Module

OFF                     = 0
ON                      = 1

EQ                      = 1
NQ                      = 2
LT                      = 3
LE                      = 4
GT                      = 5
GE                      = 6

CONFIGURATION_SEQ_UNKNOWN = 0

MESSAGE_CACHE_LEN       = 25

MAX_NUM_EVENTS          = 32

NUMBER_OF_ACCEPTING_CONFIGURATIONS = 10
ACCEPTING_RESEND        = 2

DEFAULT_FENNEC_SENSE_PERIOD = 1024

FENNEC_AM_SERIAL_PORT   = 100

NODE                    = 0xfffa
BRIDGE                  = 0xfffc
UNKNOWN                 = 0xfffd
MAX_COST                = 0xfffe
BROADCAST               = 0xffff

MAX_ADDR_LENGTH         = 8

ANY                     = 253
UNKNOWN_CONFIGURATION   = 254
UNKNOWN_LAYER           = 255


#        /* States */
S_NONE                  = 0
S_STOPPED               = 1
S_STARTING              = 2
S_STARTED               = 3
S_STOPPING              = 4
S_TRANSMITTING          = 5
S_LOADING               = 6
S_LOADED                = 7
S_CANCEL                = 8
S_ACK_WAIT              = 9
S_SAMPLE_CCA            = 10
S_SENDING_ACK           = 11
S_NOT_ACKED             = 12
S_BROADCASTING          = 13
S_HALTED                = 14
S_BRIDGE_DELAY          = 15
S_DISCOVER_DELAY        = 16
S_INIT                  = 17
S_SYNC                  = 18
S_SYNC_SEND             = 19
S_SYNC_RECEIVE          = 20
S_SEND_DONE             = 21
S_SLEEPING              = 22
S_OPERATIONAL           = 23
S_TURN_ON               = 24
S_TURN_OFF              = 25
S_PREAMBLE              = 26
S_RECEIVING		= 27

#                /* tx */
S_SFD                   = 28
S_EFD                   = 29

#                /* rx */
S_RX_LENGTH             = 30
S_RX_FCF                = 31
S_RX_PAYLOAD            = 32


#	/* Panic Levels */
PANIC_OK                = 0
PANIC_DEAD              = 1
PANIC_WARNING           = 2


#                /* Fennec System Flags */
F_RADIO			= 1
F_ADDRESSING		= 2
F_MAC   		= 3
F_QOI     		= 4
F_NETWORK               = 5
F_APPLICATION           = 6
F_EVENTS                = 7
F_MAC_ADDRESSING        = 8
F_NETWORK_ADDRESSING    = 9
F_ENGINE                = 10
F_CONTROL_UNIT          = 11
F_PRINTING              = 12
F_SENDING               = 13
F_BRIDGING              = 14
F_DATA_SRC              = 15
F_NEW_ADDR              = 16
F_NODE                  = 20
F_BRIDGE                = 21
F_BASE_STATION          = 22
F_SYSTEM                = 23
F_MEMORY                = 24

FENNEC_SYSTEM_FLAGS_NUM = 30
POLICY_CONFIGURATION    = 250



