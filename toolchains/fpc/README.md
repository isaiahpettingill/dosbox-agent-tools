# Free Pascal i8086

`make compile` runs the Free Pascal i8086 MS-DOS cross compiler in a container.
The image entry point is `ppcross8086 -Tmsdos -WmSmall`; generated files should
go under the caller's `build/` directory.

Example:

```make
$(MAKE) -C ../../toolchains/fpc compile WORKDIR="$(CURDIR)" ARGS='-FUbuild -FEbuild -oAPP.EXE src/APP.PAS'
```
