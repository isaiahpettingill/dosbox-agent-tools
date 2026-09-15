FLOPPY_SIZE := 360
PROGRAM := MAGIC8.EXE
TEST_PROGRAM := MAGIC8T.EXE
IMAGE := build/MAGIC8.IMG

.PHONY: build test image clean

build:
	mkdir -p build
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/$(PROGRAM) src/MAGIC8.C'

test:
	mkdir -p build
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-dMAGIC8_TEST -fe=build/$(TEST_PROGRAM) src/MAGIC8.C'
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=$(TEST_PROGRAM)

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
