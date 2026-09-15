# dosbox-agent-tools

Reusable, cross-platform PowerShell tools for driving [dosbox-automation](https://www.dosbox-automation.org/)'s HTTP REST API. Start a headless DOSBox instance, inject keyboard input, read the screen, swap disk images, mount host directories, and record video — for automated software installation, CI pipelines, and game-testing harnesses.

**Requires PowerShell 7+ (pwsh).** Runs on **Windows and Linux** (macOS is not supported by the setup script).

## Build DOS applications and floppies

The repository also includes a containerized 8086 DOS development workspace.
Use GNU Make and Docker or Podman from Linux (or WSL on Windows); PowerShell
is needed only for the REST automation module above.

```sh
git submodule update --init --recursive
make images CONTAINER_ENGINE=docker
make floppy NAME=magic8 CONTAINER_ENGINE=docker
make -C floppies/magic8 test CONTAINER_ENGINE=docker
```

The Makefiles automatically prefer Podman when available. Omit the override
to use that default. Compiler, emulator, asset conversion, and FAT12 image
commands run inside containers. Images are written under each floppy's
`build/` directory. Historical compiler dependencies are pinned submodules;
their upstream licenses and distribution terms still apply.

- **Compilers:** Open Watcom C, Free Pascal i8086 (including Free Vision),
  NASM, Trubo Oberon, Turbo Pascal 7, Microsoft FORTRAN 5, and the DWED
  historical compiler build environment.
- **Emulators:** NTVDM for quick command-line execution and DOSBox Automation
  for interactive testing.
- **Novelty disks:** Magic 8 Ball, the personality questionnaire, Type Fury,
  Matrix screensaver, and a deterministic nonsense-data disk.
- **Utilities:** hello-world, Hacker Tools, GW-BASIC, DWED, FreeDOS Edit,
  NAIED, PCWord, Rebel, TDE, and a [one-way ANOVA calculator](floppies/anova/README.md).
- **Agent workflow:** [AGENTS.md](AGENTS.md), [DOS references](docs/README.md),
  compiler notes, and the searchable [sample structure](samples/README.md).

See [the development workflow](docs/development.md) for prompting and testing.

For a verified example using the actual Turbo Pascal compiler from the
`dos_compilers` submodule:

```sh
make turbopascal
make -C samples/misc/turbopascal-hello test
```

Build and test the ANOVA calculator with the actual Microsoft FORTRAN 5 compiler:

```sh
make msfortran
make -C floppies/anova test image
```

## What's here

```
dosbox-agent-tools/
  dosbox-agent-tools.psm1        # module: session lifecycle + REST API wrappers
  dosbox-agent-tools.psd1        # manifest
  scripts/
    setup-dosbox-automation.ps1  # download + configure dosbox-automation (win/linux)
    build-fdpkg-manifest.ps1     # generate an fdcli fdpkg.toml from installed files
  examples/
    install-agenda.ps1           # verified Lotus Agenda 2.0 installer recipe
```

## Requirements

- PowerShell 7+ (`pwsh`) on Windows or Linux.
- [dosbox-automation](https://www.dosbox-automation.org/) 0.84-da4 or newer — install it with the setup script below.
- The primary dosbox-automation config must have:
  - `webserver_enabled = on`
  - `webserver_token_file = on`
  - `mount_allowed_bases` / `mount_allowed_image_roots` including every host directory you want to mount or read images from.
  The setup script writes all of these for you.

## Setup

```powershell
# 1. Install dosbox-automation and write the module config (Windows or Linux)
pwsh scripts/setup-dosbox-automation.ps1

# 2. Import the module (run from the repo root)
Import-Module ./dosbox-agent-tools.psd1

# 3. Start a headless session
$s = Start-DosboxSession
```

The setup script downloads the latest release from GitHub, extracts it, writes a primary `dosbox-automation.conf` with the webserver enabled, and writes `config.json` so the module knows where the binary and token file live. Pin a version with `-Version v0.84.0-da4`, and allow extra mount roots with `-MountBase D:\media`.

### Configuration precedence

The module finds dosbox-automation in this order (highest wins):

1. **Environment variables**: `DOSBOX_AUTOMATION_BIN`, `DOSBOX_AUTOMATION_TOKEN_FILE`, `DOSBOX_AUTOMATION_URL`
2. **Config file**: path from `DOSBOX_AUTOMATION_CONF`, else `%APPDATA%\dosbox-agent-tools\config.json` (Windows) or `~/.config/dosbox-agent-tools/config.json` (Linux). Fields: `dosboxBinary`, `tokenFile`, `baseUrl`.
3. **Built-in default**: base URL `http://127.0.0.1:8386`.

You can also pass `-BinaryPath`, `-TokenFile`, `-BaseUrl` explicitly to `Start-DosboxSession` / `Connect-DosboxSession` to override everything.

## Quick start

```powershell
Import-Module ./dosbox-agent-tools.psd1

# 1. Start a headless session (waits until the REST API answers)
$s = Start-DosboxSession

# 2. Swap an original floppy into A:
Set-DosboxDrive -Drive A -Image 'C:\path\to\Disk1.img'

# 3. Read the screen
(Get-DosboxScreenText).text

# 4. Type a command and press Enter (input is throttled automatically)
Invoke-DosboxCommand -Command 'dir A:'

# 5. Wait for something to appear
Wait-DosboxScreenText -Match 'Volume in drive A'

# 6. Mount a host directory as C: (verified; throws if the mount is refused)
Mount-DosboxDirectory -Drive C -HostPath 'C:\path\to\staging'

# 7. Stop cleanly
Stop-DosboxSession
```

## Key commands

| Purpose | Function |
|---|---|
| Start/stop emulator | `Start-DosboxSession`, `Stop-DosboxSession` |
| Attach to a running instance | `Connect-DosboxSession` |
| Status | `Get-DosboxStatus`, `Get-DosboxProgramState`, `Get-DosboxInfo` |
| Read screen | `Get-DosboxScreenText`, `Wait-DosboxScreenText -Match`, `Wait-DosboxScreenStable` |
| Wait for shell/prompt/program | `Wait-DosboxShell`, `Wait-DosboxPrompt`, `Wait-DosboxProgram -Match INSTALL` |
| Screenshot | `Save-DosboxScreenshot -OutFile frame.png -Mode rendered` |
| Keyboard | `Send-DosboxText`, `Send-DosboxKey -Key enter`, `Send-DosboxSequence`, `Invoke-DosboxCommand` |
| Input pacing | `Wait-DosboxInputIdle` |
| Drives | `Set-DosboxDrive -Drive A -Image <img>` (image swap), `Mount-DosboxDirectory -Drive C -HostPath <dir>` |
| Mount lock | `Lock-DosboxMounts`, `Get-DosboxMountLock` (one-way; call after installs) |
| Input recording | `Start-DosboxInputRecording`, `Stop-DosboxInputRecording`, `Get-DosboxInputRecordingStatus` |
| Video capture | `Start-DosboxVideoCapture`, `Stop-DosboxVideoCapture`, `Get-DosboxVideoCaptureStatus` |

## How input throttling works

dosbox-automation feeds `/input/type` and `/input/sequence` through a single replay queue; a send while the previous replay is still draining returns `409 Replay already in progress`. Every input function calls a per-session gate first: it waits until the previous send's busy window has elapsed (plus a small inter-send gap), then records how long this send will occupy the emulator. So you can fire keystrokes, text, and Enter presses back-to-back without manual `Start-Sleep` calls and without 409s. `Wait-DosboxInputIdle` blocks until the queue is fully drained (handy before screenshots or disk swaps).

## Gotchas learned the hard way

- **Token**: dosbox-automation regenerates the bearer token each run into the webserver config dir (`webserver/api_token`). The module reads it at session start from the configured token file.
- **`--nolocalconf`**: the module launches with `--nolocalconf` so only the primary config loads; a stray local conf in the CWD changes behavior.
- **Headless**: the module sets `SDL_VIDEODRIVER=dummy` only for the child process.
- **`t` in sequence events** is milliseconds from sequence start (PIC timing). Events at `t=0` fire immediately.
- **Screen text** is only populated in text mode (`is_text_mode: true`). For graphics-mode installers use `Save-DosboxScreenshot`.
- **`drive/swap`** autodetects floppy vs hard disk by file size and only allows images under `mount_allowed_image_roots`. Images are read-only.
- **Directory mounts** happen through the DOSBox `mount` internal command typed at the `Z:\>` shell, and are restricted by `mount_allowed_bases` (a config change there requires restarting the emulator). `Mount-DosboxDirectory` verifies the result and throws if the mount was refused.
- **PowerShell → REST body**: use `ConvertTo-Json` on a hashtable; booleans serialize as `true/false` automatically.
- **ReFS/Dev Drive mounts fail**: directory mounts refuse ReFS / Dev Drive volumes (e.g. `K:\` on the author's machine) with "isn't a directory or valid image file". Stage installs on a normal filesystem, then copy into the package `src` afterward.
- **`Invoke-RestMethod` has no `-Accept` parameter** — pass it via `-Headers`. (Handled inside the module.)
- **Installers that require the current dir**: Lotus installers reject `A:\INSTALL.EXE` run from `Z:\` with "You must run Install from the current directory" — `A:` first, then run the program name.
- **Wait for the token file to be rewritten** before reading it; dosbox-automation regenerates the token each start, and the stale token yields 401s.

## Packaging FreeDOS packages (fdcli)

For the FreeDOS package registry side, `scripts/build-fdpkg-manifest.ps1` generates an `fdcli` `fdpkg.toml` from a directory of real installed DOS files, with destination prefix derived from the package group (e.g. `APPS/` for group `apps`, `GRAPHICS/` for `graphics`). Run `pack`/`publish` from the package's work dir since manifest `source` paths are CWD-relative.
