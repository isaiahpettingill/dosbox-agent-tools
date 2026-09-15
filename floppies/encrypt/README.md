# ENCRYPT

A 1.44 MiB ambiance disk containing a 1,200,000-byte meaningless binary blob.
`CIPHER.BIN` is generated deterministically from SHA-256 blocks during the
containerized build; it is not encryption, a credential store, or a cryptographic
claim.

`INSTALL.BAT` copies the disk to `C:\APPS\ENCRYPT` and creates a short reader
wrapper in `C:\SYSTEM`.
