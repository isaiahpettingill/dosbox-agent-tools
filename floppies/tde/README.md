# TDE 5.1v

This floppy packages the supplied 16-bit real-mode DOS `TDER.EXE` edition of
the public-domain Thomson-Davis Editor 5.1v. It is a prebuilt binary package;
no compiler or additional container image is required.

TDE searches for `TDE.CFG`, `TDE.HLP`, and `TDE.SHL` beside its executable.
The image therefore places all supplied runtime configuration files at the DOS
root. `make image` creates the 1.44 MiB FAT12 disk image.
