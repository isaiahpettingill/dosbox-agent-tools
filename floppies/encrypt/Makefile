FLOPPY_SIZE := 1440
IMAGE := build/ENCRYPT.IMG
NOISE_SIZE := 1200000

.PHONY: build test image clean

build:
	rm -rf build
	mkdir -p build
	$(MAKE) -C ../../toolchains/asset-tools run WORKDIR="$(CURDIR)" COMMAND=noise ARGS='build/CIPHER.BIN $(NOISE_SIZE)'

test: build
	@echo "ENCRYPT is a deterministic binary-noise data disk; inspect CIPHER.BIN size."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/CIPHER.BIN files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
