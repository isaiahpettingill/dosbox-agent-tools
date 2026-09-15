FLOPPY_SIZE := 1440
PROGRAM := TDER.EXE
IMAGE := build/TDE.IMG
VENDOR := ../../third_party/tde51vb
CONFIG_FILES := cua.cfg de.cfg key.tdm mark.tdm menu.cfg tde.cfg tde.hlp wordstar.cfg wordstar.txt

.PHONY: build test image clean

build:
	mkdir -p build
	cp $(VENDOR)/tder.exe build/$(PROGRAM)
	cp $(VENDOR)/tde.shl build/TDE.SHL
	cp $(VENDOR)/readme.txt build/TDEINFO.TXT
	cp $(VENDOR)/config/* build/

test: build
	@echo "TDER is interactive; verify configuration discovery through DOSBox Automation when it changes."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) build/TDE.SHL build/TDEINFO.TXT $(addprefix build/,$(CONFIG_FILES)) files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
