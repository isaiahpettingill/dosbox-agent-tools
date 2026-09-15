+++
id = "turbopascal-hello"
category = "misc"
language = "pascal"
compiler = "turbo-pascal-7"
target = "dos-real-mode"
cpu = "i8086"
memory_model = "pascal-segmented"
verified = true
verified_with = ["ntvdm"]
tags = ["turbopascal", "tpc", "hello-world", "console", "writeln"]
behaviors = ["compile-dos-native-pascal", "write-console-line"]
+++

# Turbo Pascal hello-world

Compiles `HELLO.PAS` with the actual Borland Turbo Pascal 7 `TPC.EXE` in
the pinned `dos_compilers` submodule. NTVDM runs both the DOS compiler and
the resulting DOS executable inside containers. No Free Pascal compiler is
used by this sample.

From the repository root, initialize submodules and run `make turbopascal`.
Then run `make -C samples/misc/turbopascal-hello test`. The test checks that
the executable prints `Hello from Turbo Pascal 7!`. Generated files remain
under `build/`. The `{$G-}` source directive disables 286 instruction generation.

Verified on 2026-09-15 using the Turbo Pascal container built from the pinned
dependency and NTVDM under Podman/WSL. `make test` compiled six source lines
with Turbo Pascal 7.0 and checked the resulting executable's console output.
