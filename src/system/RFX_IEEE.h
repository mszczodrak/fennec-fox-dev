#ifndef RFX_IEEE_H
#define RFX_IEEE_H

typedef nx_struct ieee_radio_hdr_t {
        nxle_uint8_t length;
        nxle_uint16_t fcf;
        nxle_uint8_t dsn;
        nxle_uint16_t destpan;
        nxle_uint16_t dest;
        nxle_uint16_t src;
} ieee_radio_hdr_t;


enum {
                IEEE154_DATA_FRAME_MASK = (IEEE154_TYPE_MASK << IEEE154_FCF_FRAME_TYPE)
                        | (1 << IEEE154_FCF_INTRAPAN)
                        | (IEEE154_ADDR_MASK << IEEE154_FCF_DEST_ADDR_MODE)
                        | (IEEE154_ADDR_MASK << IEEE154_FCF_SRC_ADDR_MODE),

                IEEE154_DATA_FRAME_VALUE = (IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE)
                        | (1 << IEEE154_FCF_INTRAPAN)
                        | (IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE)
                        | (IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE),

                IEEE154_DATA_FRAME_PRESERVE = (1 << IEEE154_FCF_ACK_REQ)
                        | (1 << IEEE154_FCF_FRAME_PENDING),

                IEEE154_ACK_FRAME_LENGTH = 3,   // includes the FCF, DSN
                IEEE154_ACK_FRAME_MASK = (IEEE154_TYPE_MASK << IEEE154_FCF_FRAME_TYPE),
                IEEE154_ACK_FRAME_VALUE = (IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE),
};

#endif
