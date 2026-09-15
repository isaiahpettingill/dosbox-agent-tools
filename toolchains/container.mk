# Podman and Docker accept the build and run commands used by this repository.
# Callers may override detection: make CONTAINER_ENGINE=docker ...
CONTAINER_ENGINE ?= $(shell if command -v podman >/dev/null 2>&1; then command -v podman; elif command -v docker >/dev/null 2>&1; then command -v docker; fi)

ifeq ($(strip $(CONTAINER_ENGINE)),)
$(error no container engine found; install Podman or Docker, or set CONTAINER_ENGINE)
endif

ifneq (,$(findstring podman,$(notdir $(CONTAINER_ENGINE))))
CONTAINER_USER_ARGS := --userns=keep-id
else
CONTAINER_USER_ARGS := --user "$$(id -u):$$(id -g)"
endif
