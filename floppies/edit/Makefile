FLOPPY_SIZE := 1440
IMAGE := build/EDIT.IMG
FILES := third_party/edit-freedos/BIN/EDIT.EXE third_party/edit-freedos/BIN/EDIT.HLP third_party/edit-freedos/LICENSE third_party/edit-freedos/SOURCE/EDIT/ASCIITAB.C third_party/edit-freedos/SOURCE/EDIT/BUILD_ED.BAT third_party/edit-freedos/SOURCE/EDIT/CALENDAR.C third_party/edit-freedos/SOURCE/EDIT/CONFIG.C third_party/edit-freedos/SOURCE/EDIT/CONFIG.H third_party/edit-freedos/SOURCE/EDIT/EDIT.C third_party/edit-freedos/SOURCE/EDIT/EDIT.H third_party/edit-freedos/SOURCE/EDIT/EDIT.MAK third_party/edit-freedos/SOURCE/EDIT/EDIT.TXT third_party/edit-freedos/SOURCE/EDIT/MENUS.C floppies/edit/files/README.TXT floppies/edit/files/INSTALL.BAT

.PHONY: build test image clean

build:
	mkdir -p build
	@echo "Using the pinned FreeDOS EDIT release binary from third_party/edit-freedos/BIN."

test: build
	@echo "EDIT is interactive; verify it through DOSBox Automation when the release changes."

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)/../.." SIZE=$(FLOPPY_SIZE) OUTPUT=floppies/edit/$(IMAGE) FILES='$(FILES)'

clean:
	rm -rf build
