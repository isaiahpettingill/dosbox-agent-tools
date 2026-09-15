# Floppy Tools

`make image` creates a FAT12 disk image in a container using mtools. `SIZE` accepts
`360`, `720`, or `1440` (KiB); `mcopy` fails when the selected files do not fit.

```make
$(MAKE) -C ../../toolchains/floppy-tools image WORKDIR="$(CURDIR)" SIZE=1440 OUTPUT=build/APP.IMG FILES='build/APP.EXE files/README.TXT'
```
