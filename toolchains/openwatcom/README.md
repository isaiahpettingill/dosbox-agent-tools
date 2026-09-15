# Open Watcom

`make compile` runs Open Watcom v2 in a container with the caller's project mounted
at `/work`. The default profile is 16-bit real-mode DOS, i8086, and the small
memory model: `wcl -q -bt=dos -lr -ms -0`.

Example from a floppy Makefile:

```make
$(MAKE) -C ../../toolchains/openwatcom compile WORKDIR="$(CURDIR)" ARGS='-fe=build/APP.EXE src/APP.C'
```
