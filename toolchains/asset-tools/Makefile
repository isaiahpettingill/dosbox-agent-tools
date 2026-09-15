include ../container.mk

IMAGE ?= localhost/dos-assets:v1
WORKDIR ?= $(CURDIR)
COMMAND ?=
ARGS ?=

.PHONY: run

run:
	@test -n "$(COMMAND)" || { echo "COMMAND is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(COMMAND) $(ARGS)
