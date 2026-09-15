include ../container.mk
IMAGE ?= dosbox-agent-tools/nasm:latest
WORKDIR ?= $(CURDIR)
ARGS ?=

.PHONY: assemble

assemble:
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) $(ARGS)
