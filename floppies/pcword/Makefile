FLOPPY_SIZE := 720
IMAGE := build/PCWORD.IMG
VENDOR := ../../third_party/pcword/FDOS

.PHONY: build test image clean

build:
	rm -rf build
	mkdir -p build
	cp $(VENDOR)/BIN/RSORT.COM build/
	cp $(VENDOR)/APPINFO/PCWORD.LSM build/
	cp -a $(VENDOR)/PROGS/PCWORD build/PCWORD
	rm -rf build/PCWORD/SOURCE

test: build
	@echo "PC Word is interactive; run PCWORD.EXE in DOSBox Automation when it changes."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/RSORT.COM build/PCWORD.LSM build/PCWORD files/INSTALL.BAT'

clean:
	rm -rf build
