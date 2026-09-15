include ../container.mk
IMAGE ?= localhost/ntvdm:latest
WORKDIR ?= $(CURDIR)
PROGRAM ?=
ARGS ?=

.PHONY: run

run:
	@test -n "$(PROGRAM)" || { echo "PROGRAM is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm -i $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) -r:. ./$(PROGRAM) $(ARGS)
