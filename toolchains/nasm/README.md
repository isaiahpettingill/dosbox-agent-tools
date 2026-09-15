# NASM

`make assemble` runs NASM in a container with the caller's project mounted at
`/work`. DOS assembly defaults should use `bits 16`; `.COM` programs also use
`org 100h` and normally pass `-f bin`.
