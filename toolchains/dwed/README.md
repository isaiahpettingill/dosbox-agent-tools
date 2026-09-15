# DWED Toolchain

The DWED image contains Turbo Pascal 7 from the `dos_compilers` submodule. It
rebuilds DWED's Pascal help compiler and overlay through NTVDM, staging all
source and compiler output in the target project's `build/` directory. The
supplied Sphinx C-- binary is a Windows NT executable and cannot run under
NTVDM, so the optional path retains DWED's pinned upstream launcher.

```make
$(MAKE) -C ../../toolchains/dwed build WORKDIR="$(CURDIR)/../.." PROJECT=floppies/dwed
```
