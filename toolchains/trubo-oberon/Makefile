include ../container.mk
IMAGE ?= dosbox-agent-tools/trubo-oberon:latest
WORKDIR ?= $(CURDIR)
PROGRAM ?=
ARGS ?=

.PHONY: compile

compile:
	@test -n "$(PROGRAM)" || { echo "PROGRAM is required" >&2; exit 2; }
	$(CONTAINER_ENGINE) run --rm -i $(CONTAINER_USER_ARGS) -v "$(abspath $(WORKDIR)):/work" -w /work $(IMAGE) -r:/work -r:/toc /toc/BIN/TOC.EXE $(PROGRAM) $(ARGS)
