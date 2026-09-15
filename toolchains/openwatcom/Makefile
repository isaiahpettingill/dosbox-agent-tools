include ../container.mk
IMAGE ?= localhost/dos-openwatcom:v2
WORKDIR ?= $(CURDIR)
ARGS ?=

.PHONY: compile

compile:
	$(CONTAINER_ENGINE) run --rm $(CONTAINER_USER_ARGS) -e HOME=/tmp -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) wcl -q -bt=dos -lr -ms -0 $(ARGS)
