COMPONENT=$(FENNEC_FOX_LIB)/Fennec/FennecC
SFC_GEN=$(FENNEC_FOX_LIB)/Fennec/sfc

#SYSTEM_CORE_FREQUENCY := 104
#SYSTEM_BUS_FREQUENCY := 104
PFLAGS+=-DTOSH_DATA_LENGTH=127
#PFLAGS+=-DENABLE_SPI0_DMA
#PFLAGS+=-DENABLE_SPI1_DMA

include $(MAKERULES)
include $(FENNEC_FOX_LIB)/support/sfc/fennec.extra

#PFLAGS+=-D__DBGS__

# 2. TinyOS printf
CFLAGS += -I$(TOSDIR)/lib/printf
CFLAGS += -DPRINTF_BUFFER_SIZE=1000
CFLAGS += -DFENNEC_TOS_PRINTF
#CFLAGS += -DFENNEC_LOGGER

#CFLAGS+=-D_H_IMB400_CAMERA_H
#CFLAGS+=-D_H_IMB400_AUDIO_H

clean: FORCE
	rm -rf build $(CLEAN_EXTRA) pp
	rm -rf _TOSSIMmodule.so TOSSIM.pyc TOSSIM.py app.xml simbuild
	rm -rf VolumeMapC.nc
	if [ -d $(SFC_GEN) ]; then rm -rf $(SFC_GEN); fi
	rm -f $(COMPONENT).cmap $(COMPONENT).dot $(COMPONENT).html $(COMPONENT).png

