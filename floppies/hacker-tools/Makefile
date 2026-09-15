FLOPPY_SIZE := 360
IMAGE := build/HACKTOOLS.IMG
PROGRAMS := STRINGS.EXE DISASM.EXE SERMON.EXE PATCH.EXE ASMLITE.EXE

.PHONY: build test image clean

build:
	mkdir -p build
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/STRINGS.EXE src/STRINGS.C'
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/DISASM.EXE src/DISASM.C'
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/SERMON.EXE src/SERMON.C'
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/PATCH.EXE src/PATCH.C'
	$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/ASMLITE.EXE src/ASMLITE.C'

test: build
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)" PROGRAM=build/STRINGS.EXE ARGS='assets/STRTEST.DAT 4'
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)" PROGRAM=build/ASMLITE.EXE ARGS='assets/HELLO.ASM build/HELLO.COM'
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)" PROGRAM=build/DISASM.EXE ARGS='build/HELLO.COM'
	$(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)" PROGRAM=build/PATCH.EXE ARGS='build/HELLO.COM 0 90'
	@echo "SERMON requires a physical or emulated serial device; inspect it interactively."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/STRINGS.EXE build/DISASM.EXE build/SERMON.EXE build/PATCH.EXE build/ASMLITE.EXE src/STRINGS.C src/DISASM.C src/SERMON.C src/PATCH.C src/ASMLITE.C LICENSE.TXT files/README.TXT files/INSTALL.BAT'

clean:
	rm -rf build
