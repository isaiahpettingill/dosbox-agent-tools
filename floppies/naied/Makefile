FLOPPY_SIZE := 1440
PROGRAM := NAIED.EXE
IMAGE := build/NAIED.IMG
VENDOR := ../../third_party/naied

.PHONY: build test image clean

build:
	rm -rf build
	mkdir -p build/units
	cp -a $(VENDOR)/src build/src
	# Free Pascal 3.2.2 cannot compile this far interrupt-vector assignment.
	# Ctrl-Break remains at its DOS default; upstream source is not modified.
	sed -i '/SetIntVec(\$$23, @BlankHandle);/d; /SetIntVec(\$$23, OldCtrlBreakHandle);/d' build/src/keyboard.pas
	cp $(VENDOR)/LICENSE build/NAIED.LIC
	cp $(VENDOR)/README.md build/NAIED.TXT
	$(MAKE) -C ../../toolchains/fpc compile WORKDIR="$(CURDIR)" ARGS='-WmCompact -FUbuild/units -FEbuild -o$(PROGRAM) build/src/naied.lpr'

test: build
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=$(PROGRAM) ARGS=-h

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/$(PROGRAM) build/NAIED.LIC build/NAIED.TXT files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
