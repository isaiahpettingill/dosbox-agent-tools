include ../container.mk
IMAGE ?= localhost/dos-msfortran:5
WORKDIR ?= $(CURDIR)
PROGRAM ?=
ARGS ?=

.PHONY: compile

compile:
	@test -n "$(PROGRAM)" || { echo "PROGRAM is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(PROGRAM) $(ARGS)
