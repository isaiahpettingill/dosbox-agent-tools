# NaiED

NaiED is Kagamma's MIT-licensed text editor for 16-bit real-mode DOS. The
source is pinned as the `third_party/naied` submodule at commit
`0ce1f6c21a077bf98ad4787e19c57710452f9806`.

`make build` stages the upstream source then builds it with the existing Free
Pascal i8086/MS-DOS container using its required compact memory model.
`make test` runs NaiED's noninteractive `-h` path through NTVDM. `make image`
creates a 1.44 MiB FAT12 floppy.

Free Pascal 3.2.2 cannot compile NaiED's far Ctrl-Break interrupt-vector
assignment. The build removes only that installation/restoration pair from its
temporary staged source; Ctrl-Break retains the DOS default and the upstream
submodule is unchanged.
