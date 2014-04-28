COMPONENT=$(FENNEC_FOX_LIB)/Fennec/FennecC
SFC_GEN=$(FENNEC_FOX_LIB)/Fennec/sfc
PFLAGS+=-DTOSH_DATA_LENGTH=127

CFLAGS += -DLOW_POWER_LISTENING

include $(FENNEC_FOX_LIB)/support/make/Makerules
include $(MAKERULES)
include $(FENNEC_FOX_LIB)/support/make/tinyos.extra

PFLAGS+=-D__DBGS__

# 2. TinyOS printf
CFLAGS += -I$(TOSDIR)/lib/printf
#CFLAGS += -DPRINTF_BUFFER_SIZE=200
CFLAGS += -DFENNEC_TOS_PRINTF
#CFLAGS += -DFENNEC_COOJA_PRINTF

clean: FORCE
	rm -rf build $(CLEAN_EXTRA) pp
	rm -rf doc
	rm -rf _TOSSIMmodule.so TOSSIM.pyc TOSSIM.py app.xml simbuild
	rm -rf VolumeMapC.nc
	if [ -d $(SFC_GEN) ]; then rm -rf $(SFC_GEN); fi
	rm -f $(COMPONENT).cmap $(COMPONENT).dot $(COMPONENT).html $(COMPONENT).png

