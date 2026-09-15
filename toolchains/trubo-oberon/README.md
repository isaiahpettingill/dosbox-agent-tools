# Trubo Oberon

The container image contains the DOS-native Trubo Oberon compiler and runs it through
NTVDM. `make compile PROGRAM=MAIN.MOD` invokes `/toc/BIN/TOC.EXE` with the
current project mounted at `/work`. This toolchain is isolated so its DOS
environment and library paths do not leak into floppy Makefiles.
