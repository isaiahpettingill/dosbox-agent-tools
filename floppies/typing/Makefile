FLOPPY_SIZE := 1440
PROGRAM := TYPEFURY.EXE
TEST_PROGRAM := TYPEFURY_TEST.EXE
IMAGE := build/TYPEFURY.IMG

.PHONY: build test image clean

build:
	mkdir -p build
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fo=build/TYPEFURY.o -fe=build/$(PROGRAM) src/TYPEFURY.C'

test:
	mkdir -p build
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fo=build/TYPEFURY_TEST.o -fe=build/$(TEST_PROGRAM) src/TYPEFURY_TEST.C'
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=$(TEST_PROGRAM)

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
