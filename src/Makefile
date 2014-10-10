COMPONENT=$(FENNEC_FOX_LIB)/Fennec/FennecC
TINYOS_ROOT_DIR?=/home/msz/github/tinyos

SFC_GEN=$(FENNEC_FOX_LIB)/Fennec/sfc
PFLAGS+=-DTOSH_DATA_LENGTH=127

CFLAGS += -DLOW_POWER_LISTENING

PFLAGS+=-D__USUAL_LEDS__
PFLAGS+=-D__FLOCKLAB_LEDS__

include $(FENNEC_FOX_LIB)/support/make/Makerules
include $(FENNEC_FOX_LIB)/support/make/dbgs.extra
include $(TINYOS_ROOT_DIR)/Makefile.include

# 2. TinyOS printf
#CFLAGS += -I$(TINYOS_OS_DIR)/lib/printf
#CFLAGS += -DPRINTF_BUFFER_SIZE=200
#CFLAGS += -DFENNEC_TOS_PRINTF
#CFLAGS += -DFENNEC_COOJA_PRINTF

clean: FORCE
	rm -rf build $(CLEAN_EXTRA) pp
	rm -rf doc
	rm -rf _TOSSIMmodule.so TOSSIM.pyc TOSSIM.py app.xml simbuild
	rm -rf VolumeMapC.nc
	if [ -d $(SFC_GEN) ]; then rm -rf $(SFC_GEN); fi
	rm -f $(COMPONENT).cmap $(COMPONENT).dot $(COMPONENT).html $(COMPONENT).png

