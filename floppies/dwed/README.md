# DWED

DWED is a real-mode DOS text editor and IDE from DosWorld. By default the
floppy packages its pinned, upstream `BIN/` release. The optional `make
rebuild` target rebuilds its Turbo Pascal 7 help compiler and overlay; all
staged source and compiler output remains under `build/`. The supplied Sphinx
C-- compiler is a Windows NT executable and cannot run under NTVDM, so the
optional path retains the pinned upstream C-- launcher.

The image includes `DWED.EXE`, `DWEDOVL.EXE`, and `DWED.CFG`; all three runtime
files must remain together. `make test` verifies the build only because DWED
is keyboard-driven and should be exercised with DOSBox Automation when its UI
changes.
