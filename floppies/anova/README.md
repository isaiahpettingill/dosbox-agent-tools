# One-way ANOVA calculator

An interactive DOS calculator compiled by the actual Microsoft FORTRAN 5.0
toolchain from the pinned `dos_compilers` submodule. Accepts 2-10 groups of
1-100 observations each, including unequal group sizes. Reports group and
grand means, between/within/total sums of squares, degrees of freedom, mean
squares, and F. Uses double precision and centered sums of squares.

```sh
make msfortran
make -C floppies/anova test image
```

Run `ANOVA.EXE` and enter a data filename (`KNOWN.TXT` for the example), or
press Enter to type the data interactively. Enter one number per line, with
a group size before each group's observations. The
360 KiB FAT12 image includes the executable, source, instructions, installer,
and known dataset. `/FPc` uses software floating point on an 8086.

The calculator implements ordinary one-way ANOVA, with no p-values, post-hoc
comparisons, repeated measures, or unequal-variance correction. The classical
F interpretation assumes independent observations, normal errors, and equal
population variances. See [NIST's one-factor ANOVA reference](https://www.itl.nist.gov/div898/handbook/eda/section3/eda354.htm).

Numeric inputs are limited to absolute values at most `1E100`; counts must be
integers within the displayed limits. Invalid or incomplete input produces an
error. Zero within-group variance produces an undefined F instead of division
by zero. There must be more total observations than groups.

`make test` runs the compiled DOS executable on balanced, unequal-size,
constant, invalid-count, singleton-only, and truncated-input datasets and
checks the actual output in a Python container.

Verified on 2026-09-15: Microsoft FORTRAN 5.00 compiled and linked the program;
all six datasets passed through the resulting DOS executable under NTVDM.
The example returns SS between = 24, SS within = 6, and F = 12. The image
build produced a 360 KiB FAT12 floppy containing the 40 KiB executable.
