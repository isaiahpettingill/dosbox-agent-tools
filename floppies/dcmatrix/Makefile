FLOPPY_SIZE := 360
IMAGE := build/DCMATRIX.IMG
VENDOR := ../../third_party/dcmatrix/FDOS

.PHONY: build test image clean

build:
	mkdir -p build
	cp $(VENDOR)/BIN/dcmatrix.com build/DCMATRIX.COM
	cp $(VENDOR)/APPINFO/DCMATRIX.LSM build/README.TXT
	cp $(VENDOR)/SOURCE/DCMATRIX/COPYING build/COPYING

test: build
	@echo "DeciMatrix is interactive; run DCMATRIX.COM in DOSBox Automation when it changes."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/DCMATRIX.COM build/README.TXT build/COPYING files/INSTALL.BAT'

clean:
	rm -rf build
