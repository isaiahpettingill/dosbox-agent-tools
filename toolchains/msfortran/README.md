# Microsoft FORTRAN 5.0

Runs the actual DOS `FL.EXE` compiler driver, compiler passes, and linker from
the pinned `Microsoft Fortran v5` directory in `dos_compilers`, through NTVDM.
`/FPc` selects software floating point, so the output does not need an 8087.
No 286 instruction-generation option is enabled. The compiler's original
upstream distribution terms apply.

```sh
git submodule update --init third_party/dos_compilers
make msfortran
make -C floppies/anova test image
```

Stage fixed-form `.FOR` source in `build/`, then pass that directory as
`WORKDIR` and the uppercase DOS source filename as `PROGRAM`. The wrapper
stages `.FOR` and `.INC` inputs beside the compiler in a temporary directory
inside the container: this bound DOS compiler cannot load through directory
symlinks. It copies the resulting executable back into `WORKDIR`.
