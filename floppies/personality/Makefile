FLOPPY_SIZE := 1440
PROGRAM := IPIPTEST.EXE
IMAGE := build/IPIPTEST.IMG

.PHONY: build test image clean

build:
	mkdir -p build
	$(MAKE) -C ../../toolchains/fpc compile WORKDIR="$(CURDIR)" ARGS='-FUbuild -FEbuild -o$(PROGRAM) src/IPIPTEST.PAS'

test: build
	@echo "IPIPTEST requires an interactive DOSBox Automation test; build completed."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
