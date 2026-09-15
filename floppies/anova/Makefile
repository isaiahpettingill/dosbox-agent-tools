include ../../toolchains/container.mk
FLOPPY_SIZE := 360
IMAGE := build/ANOVA.IMG

.PHONY: build test image clean

build:
	mkdir -p build
	cp src/ANOVA.FOR build/ANOVA.FOR
	$(MAKE) -C ../../toolchains/msfortran compile WORKDIR="$(CURDIR)/build" PROGRAM=ANOVA.FOR

test: build
	@set -e; for case in known unequal zero invalid singleton truncated; do \
	  cp tests/$$case.txt build/INPUT.DAT; \
	  printf 'INPUT.DAT\r\n' | $(MAKE) -C ../../toolchains/ntvdm run WORKDIR="$(CURDIR)/build" PROGRAM=ANOVA.EXE > build/$$case.out 2>&1 || test "$$case" = invalid || test "$$case" = singleton || test "$$case" = truncated; \
	done
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(CURDIR):/work" -w /work --entrypoint python3 localhost/dos-assets:v1 tests/check.py

image: build
	$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=$(FLOPPY_SIZE) OUTPUT=$(IMAGE) FILES='build/ANOVA.EXE files/README.TXT files/INSTALL.BAT tests/known.txt src/ANOVA.FOR'

clean:
	rm -rf build
