include ../container.mk
IMAGE ?= localhost/dos-dwed:tp7
WORKDIR ?= $(CURDIR)
PROJECT ?=

.PHONY: build

build:
	@test -n "$(PROJECT)" || { echo "PROJECT is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(PROJECT)
