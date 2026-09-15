include ../container.mk
IMAGE ?= localhost/dos-fpc:3.2.2
WORKDIR ?= $(CURDIR)
ARGS ?=

.PHONY: compile

compile:
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -e HOME=/tmp -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(ARGS)
