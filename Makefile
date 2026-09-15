include toolchains/container.mk

IMAGE_TARGETS := openwatcom fpc8086 nasm trubo-oberon ntvdm dosbox-automation floppy-tools asset-tools dwed-toolchain turbopascal msfortran
IMAGE_openwatcom := localhost/dos-openwatcom:v2
IMAGE_fpc8086 := localhost/dos-fpc:3.2.2
IMAGE_nasm := dosbox-agent-tools/nasm:latest
IMAGE_trubo-oberon := dosbox-agent-tools/trubo-oberon:latest
IMAGE_ntvdm := localhost/ntvdm:latest
IMAGE_dosbox-automation := dosbox-agent-tools/dosbox-automation:latest
IMAGE_floppy-tools := localhost/dos-floppy:v3
IMAGE_asset-tools := localhost/dos-assets:v1
IMAGE_dwed-toolchain := localhost/dos-dwed:tp7
IMAGE_turbopascal := localhost/dos-turbopascal:7
IMAGE_msfortran := localhost/dos-msfortran:5
FLOPPIES := $(sort $(notdir $(patsubst %/Makefile,%,$(wildcard floppies/*/Makefile))))
SAMPLES := $(sort $(dir $(wildcard samples/*/*/Makefile)))

.PHONY: images samples floppies floppy clean $(IMAGE_TARGETS) $(FLOPPIES)

images: $(IMAGE_TARGETS)

$(filter-out dwed-toolchain turbopascal msfortran,$(IMAGE_TARGETS)):
	@if $(CONTAINER_ENGINE) image inspect "$($(addprefix IMAGE_,$@))" >/dev/null 2>&1; then \
		printf 'Already built: %s\n' "$($(addprefix IMAGE_,$@))"; \
	else \
		$(CONTAINER_ENGINE) build --tag "$($(addprefix IMAGE_,$@))" containers/$@; \
	fi

dwed-toolchain: ntvdm
	@if $(CONTAINER_ENGINE) image inspect "$(IMAGE_dwed-toolchain)" >/dev/null 2>&1; then \
		printf 'Already built: %s\n' "$(IMAGE_dwed-toolchain)"; \
	else \
		$(CONTAINER_ENGINE) build --tag "$(IMAGE_dwed-toolchain)" --file containers/dwed/Containerfile .; \
	fi

turbopascal: ntvdm
	@if $(CONTAINER_ENGINE) image inspect "$(IMAGE_turbopascal)" >/dev/null 2>&1; then \
		printf 'Already built: %s\n' "$(IMAGE_turbopascal)"; \
	else \
		$(CONTAINER_ENGINE) build --tag "$(IMAGE_turbopascal)" --file containers/turbopascal/Containerfile .; \
	fi

samples:
	@for sample in $(SAMPLES); do $(MAKE) -C $$sample build; done

msfortran: ntvdm
	@if $(CONTAINER_ENGINE) image inspect "$(IMAGE_msfortran)" >/dev/null 2>&1; then \
		printf 'Already built: %s\n' "$(IMAGE_msfortran)"; \
	else \
		$(CONTAINER_ENGINE) build --tag "$(IMAGE_msfortran)" --file containers/msfortran/Containerfile .; \
	fi

floppies: $(FLOPPIES)

$(FLOPPIES):
	$(MAKE) -C floppies/$@ image

floppy:
	@test -n "$(NAME)" || { echo "usage: make floppy NAME=<name>" >&2; exit 2; }
	@test -f "floppies/$(NAME)/Makefile" || { echo "unknown floppy: $(NAME)" >&2; exit 2; }
	$(MAKE) -C floppies/$(NAME) image

clean:
	@for sample in $(SAMPLES); do $(MAKE) -C $$sample clean; done
	@for floppy in $(FLOPPIES); do $(MAKE) -C floppies/$$floppy clean; done
