FLOPPY_SIZE := 720
IMAGE := build/REBEL.IMG
VENDOR := ../../third_party/rebel/FDOS

.PHONY: build test image clean

build:
	rm -rf build
	mkdir -p build
	cp $(VENDOR)/APPINFO/REBEL.LSM build/
	cp -a $(VENDOR)/PROGS/REBEL build/REBEL

test: build
	@echo "Rebel is interactive; run REBEL.EXE in DOSBox Automation when it changes."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/REBEL.LSM build/REBEL files/INSTALL.BAT'

clean:
	rm -rf build
