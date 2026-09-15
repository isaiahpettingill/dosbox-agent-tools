FLOPPY_SIZE := 360
IMAGE := build/GWBASIC.IMG
VENDOR := ../../third_party/gwbasic
FILES := GWBASIC.EXE GWBASICA.EXE LICENSE ORIGIN.TXT

.PHONY: build test image clean

build:
	mkdir -p build
	cp $(addprefix $(VENDOR)/,$(FILES)) build/

test: build
	@echo "GW-BASIC is interactive; start GWBASIC.EXE in NTVDM or DOSBox Automation to verify it."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='$(addprefix build/,$(FILES)) files/README.TXT files/HELP.TXT files/INSTALL.BAT'

clean:
	rm -rf build
