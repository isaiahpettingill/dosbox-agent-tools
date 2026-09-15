FLOPPY_SIZE := 1440
IMAGE := build/DWED.IMG
FILES := third_party/dwed/BIN/DWED.EXE third_party/dwed/BIN/DWEDOVL.EXE third_party/dwed/BIN/DWED.CFG third_party/dwed/LICENSE floppies/dwed/files/README.TXT floppies/dwed/files/INSTALL.BAT

.PHONY: build rebuild test image clean

build:
	mkdir -p build
	@echo "Using the pinned DWED release binaries from third_party/dwed/BIN."

rebuild:
	$(MAKE) -C ../../toolchains/dwed build WORKDIR="$(CURDIR)/../.." PROJECT=floppies/dwed

test: rebuild
	@echo "DWED Turbo Pascal overlay rebuild completed; the pinned C-- launcher is retained."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)/../.." SIZE=$(FLOPPY_SIZE) OUTPUT=floppies/dwed/$(IMAGE) FILES='$(FILES)'

clean:
	rm -rf build
