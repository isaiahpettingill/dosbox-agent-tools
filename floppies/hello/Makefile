FLOPPY_SIZE := 360
PROGRAM := HELLO.EXE
IMAGE := build/HELLO.IMG

.PHONY: build test image clean

build:
	mkdir -p build
	$(MAKE) -C ../../toolchains/fpc compile WORKDIR="$(CURDIR)" ARGS='-FUbuild -FEbuild -o$(PROGRAM) src/HELLO.PAS'

test: build
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=$(PROGRAM)

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
