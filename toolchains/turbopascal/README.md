# Turbo Pascal 7

The container runs the actual DOS `TPC.EXE` from the pinned
`third_party/dos_compilers/Borland Turbo Pascal v7` dependency through NTVDM.
It adjusts the compiler's unit path inside the image; the submodule remains
unchanged. Compiler distribution terms remain those of the upstream software.

```sh
git submodule update --init third_party/dos_compilers
make turbopascal
make -C samples/misc/turbopascal-hello test
```

The toolchain mounts `WORKDIR` as its DOS working directory. Stage source in
`build/` first so generated DOS files stay there. Pass a DOS-compatible source
filename as `PROGRAM` and optional compiler flags as `ARGS`. Keep 8086 code
generation enabled (`-$G-`).
