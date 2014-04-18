#ifndef __SIMPLE_NET_H_
#define __SIMPLE_NET_H_

#define MORE_BIT	15
#define MORE_COMES 	(1<<MORE_BIT)

#define SDRP_TYPE_MSG			0
#define SDRP_DATA			1
#define SDRP_DISCOVER			2
#define SDRP_BRIDGE_REPLY		3
#define SDRP_BRIDGE_REPLY_FAILED	4
#define SDRP_PRE_CHECK			5

#define PRE_CHECK_DELAY 20
#define DISCOVER_DELAY	50
#define BRIDGE_DELAY    (DISCOVER_DELAY * 3 )
#define SDRP_MIN_LQI	90
#define PRE_CHECK_REPEAT 7
#define INITIAL_DISCOVERY_DELAY (PRE_CHECK_REPEAT * PRE_CHECK_DELAY)


enum {
	/* link cost metricts */
	SIMPLE_LQI = 1,
	PRE_CHECK = 2,
	JUST_ONE = 3,

	SDRP_MAX_COST = 50,

	/* pre check max repeat */
	PRE_CHECK_SIZE = 25,

	/* max number of path */
	SDRP_MAX_PATHS = 2,

	SDRP_BRIDGE_MAX_PATHS = 1,
};

typedef struct costab_t {
  uint16_t dst;
  uint16_t cost;
  uint16_t next;
  uint16_t on_path;
} costab_t;


typedef struct p2p_t {
  uint8_t id;
  uint16_t data_src;
  uint16_t bridge;
  uint16_t next_to_data;
  uint16_t next_to_bridge;
  uint16_t cost;
  uint32_t usage;
} p2p_t;

typedef nx_struct sdrp_header {
  nx_uint8_t flags;
  nx_uint16_t destination;
  nx_uint8_t seq;
  nx_uint8_t payload_size;
  nx_uint8_t (COUNT(0) payload)[0];
} sdrp_header_t;

typedef nx_struct sdrp_discover {
  nx_uint8_t flags;
  nx_uint8_t id;
  nx_uint16_t discover;  /* Discover address */
  nx_uint16_t bridge;    /* Bridge address */
  nx_uint16_t cost;      /* Cost to destination */
  nx_uint16_t last;      /* Last hop, the sending one address */
} sdrp_discover_t;

typedef struct pre_check_entry {
  uint16_t addr;
  uint8_t value;
} pre_check_entry_t;


#endif
