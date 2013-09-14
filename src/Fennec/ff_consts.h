#ifndef FF_CONSTANTS_H
#define FF_CONSTANTS_H


#define TYPE_NONE	0
#define TYPE_SECOND	1
#define TYPE_MINUTE	2
#define TYPE_HOUR	3
#define TYPE_DAY	4

enum {
        OFF                     = 0,
        ON                      = 1,

        UP                      = 0,
        DOWN                    = 1,

        EQ                      = 1,
        NQ                      = 2,
        LT                      = 3,
        LE                      = 4,
        GT                      = 5,
        GE                      = 6,

        CONFIGURATION_SEQ_UNKNOWN = 0,

        MESSAGE_CACHE_LEN       = 25,

	MAX_NUM_EVENTS		= 32,

	NUMBER_OF_ACCEPTING_CONFIGURATIONS = 10,
	ACCEPTING_RESEND	= 2,

        DEFAULT_FENNEC_SENSE_PERIOD = 1024,

	NODE			= 0xfffa,
        BRIDGE                  = 0xfffc,
        UNKNOWN                 = 0xfffd,
        MAX_COST                = 0xfffe,
        BROADCAST               = 0xffff,

	MAX_ADDR_LENGTH		= 8, 		/* in bytes */

	F_MINIMUM_STATE_LEVEL	= 0,


	ANY			= 253,
        UNKNOWN_CONFIGURATION   = 0xfff9,
        UNKNOWN_LAYER           = 255,
	UNKNOWN_ID		= 0xfff0,

                /* Panic Levels */
        PANIC_OK                = 0,
        PANIC_DEAD              = 1,
        PANIC_WARNING           = 2,

	F_NODE			= 20,
	F_BRIDGE		= 21,
	F_BASE_STATION		= 22,

	F_SYSTEM		= 23,
	F_MEMORY		= 24,
	F_SENSOR		= 25,

        FENNEC_SYSTEM_FLAGS_NUM = 30,
	POLICY_CONFIGURATION	= 250,
	FENNEC_MSG_DATA_LEN	= 128,
};

#endif
