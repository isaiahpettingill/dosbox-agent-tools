<#
    install-agenda.ps1 -- drives the Lotus Agenda 2.0 installer (4 disks) headlessly
    and stages the real installed files. Verified against the original media set.

    Flow (all screen-driven, not timing-based):
      1. Mount Disk1.img on A:, mount a host dir as C:
      2. Run INSTALL.EXE from A:\ (it requires running from the current dir)
      3. Welcome -> Enter; drive C (default), dir AGENDA -> Enter
      4. Confirm drive/dir -> Y; print/preview files -> Y (default)
      5. VGA display driver (default); select Generic printer (SPACE + ENTER)
      6. Swap disks on request: Disk2 (Utilities/Apps), Disk3 (Print 1), Disk4 (Print 2)
      7. "successfully installed" -> any key

    Usage:
        pwsh examples\install-agenda.ps1
#>
[CmdletBinding()]
param(
    [string]$ModulePath = $null,
    [string]$MediaDir    = $env:AGENDA_MEDIA_DIR,
    [string]$StageRoot   = $env:AGENDA_STAGE_ROOT,
    [string]$AppDir      = 'AGENDA',
    [switch]$KeepRunning
)

$ErrorActionPreference = 'Stop'
if (-not $ModulePath) {
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'dosbox-agent-tools.psd1'
}
Import-Module $ModulePath -Force

if (-not $MediaDir) {
    throw "Set AGENDA_MEDIA_DIR to the folder containing Disk1-4.img (or pass -MediaDir)."
}
if (-not $StageRoot) {
    throw "Set AGENDA_STAGE_ROOT to an NTFS staging folder (or pass -StageRoot). dosbox-automation refuses directory mounts on ReFS/Dev Drive (e.g. K:\ on this machine)."
}

# NOTE: staging must live on an NTFS drive. K:\ is a ReFS Dev Drive and
# dosbox-automation's directory mount refuses it ("isn't a directory").
$outputDir = Join-Path $StageRoot 'installed'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$session = Start-DosboxSession
try {
    Set-DosboxDrive -Drive A -Image (Join-Path $MediaDir 'Disk1.img')
    Wait-DosboxShell

    # C: mount MUST happen before the installer runs (it probes the drive type)
    Mount-DosboxDirectory -Drive C -HostPath $outputDir

    Invoke-DosboxCommand -Command 'A:' -PressEnter
    Start-Sleep -Milliseconds 800
    Invoke-DosboxCommand -Command 'INSTALL.EXE' -PressEnter
    Wait-DosboxScreenText -Match 'Press ENTER to begin' -TimeoutSec 20

    Send-DosboxKey -Key enter                                  # welcome
    Wait-DosboxScreenText -Match 'Specify Your Hard-Disk Drive' -TimeoutSec 10
    Send-DosboxKey -Key enter                                  # drive C (default)
    Start-Sleep -Milliseconds 1000
    Send-DosboxText -Text $AppDir                              # directory name
    Start-Sleep -Milliseconds 500
    Send-DosboxKey -Key enter
    Wait-DosboxScreenText -Match 'correct' -TimeoutSec 10
    Send-DosboxText -Text 'Y'                                  # confirm drive/dir
    Start-Sleep -Milliseconds 400
    Send-DosboxKey -Key enter

    Wait-DosboxScreenText -Match 'Print and Preview Files' -TimeoutSec 15
    Send-DosboxKey -Key enter                                  # Y (default)
    Wait-DosboxScreenText -Match 'Display Driver' -TimeoutSec 10
    Send-DosboxKey -Key enter                                  # VGA (default)
    Wait-DosboxScreenText -Match 'Select Printers' -TimeoutSec 10
    Send-DosboxKey -Key space                                  # Generic printer
    Start-Sleep -Milliseconds 400
    Send-DosboxKey -Key enter

    # Disk swaps, in the order the installer requests them
    $swap = @(
        @{ Prompt = 'Utilities and Applications'; Image = 'Disk2.img' },
        @{ Prompt = 'Print Disk 1';               Image = 'Disk3.img' },
        @{ Prompt = 'Print Disk 2';               Image = 'Disk4.img' }
    )
    foreach ($s in $swap) {
        Wait-DosboxScreenText -Match ('Insert the disk labeled ' + [regex]::Escape($s.Prompt)) -TimeoutSec 60
        Set-DosboxDrive -Drive A -Image (Join-Path $MediaDir $s.Image)
        Start-Sleep -Seconds 1
        Send-DosboxKey -Key enter
        Start-Sleep -Seconds 4
    }

    Wait-DosboxScreenText -Match 'successfully installed Agenda' -TimeoutSec 120 -FailIfExit
    Send-DosboxKey -Key enter                                  # back to shell

    # Smoke test: launch Agenda and confirm the File Retrieve dialog appears
    Invoke-DosboxCommand -Command 'AGENDA' -PressEnter
    Wait-DosboxScreenText -Match 'File Retrieve' -TimeoutSec 30 -FailIfExit
    Save-DosboxScreenshot -OutFile (Join-Path (Split-Path -Parent $StageRoot) 'agenda-running.png') -Format png -Mode raw
}
finally {
    if (-not $KeepRunning) { Stop-DosboxSession -Force }
}

$installed = Join-Path $outputDir $AppDir
Write-Host "Installed files staged in: $installed"
Write-Host "Next: copy to work\agenda\src and rebuild fdpkg.toml (see scripts\build-fdpkg-manifest.ps1)"