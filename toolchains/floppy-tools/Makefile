include ../container.mk
IMAGE ?= localhost/dos-floppy:v3
WORKDIR ?= $(CURDIR)
SIZE ?= 1440
OUTPUT ?=
FILES ?=

.PHONY: image

image:
	@test -n "$(OUTPUT)" || { echo "OUTPUT is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(SIZE) $(OUTPUT) $(FILES)
