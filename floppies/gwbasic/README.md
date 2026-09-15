# GW-BASIC Floppy

Packages the `20221216` pre-release binaries from [TK Chia's GW-BASIC
release](https://gitlab.com/tkchia/GW-BASIC/-/releases/20221216): the standard
`GWBASIC.EXE` and experimental `GWBASICA.EXE` interpreter. The upstream source
is MIT licensed; the image includes the full license and release provenance.

`INSTALL.BAT` copies the disk to `C:\APPS\GWBASIC` and creates `GWBASIC.BAT`
and `GWBASICA.BAT` in `C:\SYSTEM`.

Build the FAT12 image with:

```text
make image
```
