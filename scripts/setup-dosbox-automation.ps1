#requires -Version 7
<#
    setup-dosbox-automation.ps1
    Install dosbox-automation and configure it for headless API use on Windows or
    Linux, then write the dosbox-agent-tools module config so Start-DosboxSession
    works with zero arguments.

    What it does:
      1. Detects the platform (Windows / Linux; macOS is not supported).
      2. Downloads the latest (or a pinned) dosbox-automation release from GitHub.
      3. Extracts it into an install directory.
      4. Writes the primary dosbox-automation.conf into dosbox-automation's config
         directory (the one it reads at startup — $XDG_CONFIG_HOME/dosbox-automation
         on Linux, %LOCALAPPDATA%\dosbox-automation on Windows) with the webserver
         enabled, the bearer token written to a file, and mount_allowed_bases /
         image roots set so directory mounts and floppy/CD swaps are allowed.
      5. Writes the dosbox-agent-tools module config (config.json) that the module
         reads to locate the binary, token file, and base URL.

    Usage:
        pwsh scripts/setup-dosbox-automation.ps1                      # latest
        pwsh scripts/setup-dosbox-automation.ps1 -Version v0.84.0-da4 # pinned
        pwsh scripts/setup-dosbox-automation.ps1 -MountBase D:\media   # extra mount root

    Overrides:
        DOSBOX_AUTOMATION_INSTALL_DIR  install dir (default ~/.local/share/... or %LOCALAPPDATA%\...)
        DOSBOX_AUTOMATION_CONF_DIR     dosbox-automation config dir (default $XDG_CONFIG_HOME/dosbox-automation
                                       or %LOCALAPPDATA%\dosbox-automation)
        DOSBOX_AUTOMATION_CONF         module config file path override (default .../dosbox-agent-tools/config.json)
#>
[CmdletBinding()]
param(
    [string]$Version = 'latest',
    [string]$InstallDir = $null,
    [string]$ConfigDir = $null,
    [string[]]$MountBase = @(),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if ($IsMacOS) {
    throw 'macOS is not supported. dosbox-automation and this script target Windows and Linux only.'
}
if (-not ($IsWindows -or $IsLinux)) {
    throw "Unsupported platform. Expected Windows or Linux, got '$([System.Environment]::OSVersion.Platform)'."
}

Write-Host "[setup] Platform: $(if ($IsWindows) { 'Windows' } else { 'Linux' })"

$releaseApi = 'https://api.github.com/repos/dosbox-automation/dosbox-automation/releases'

function Get-Releases {
    param([string]$Uri)
    Write-Host "[setup] Querying $Uri"
    try {
        $headers = @{}
        if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
        return Invoke-RestMethod -Uri $Uri -Headers $headers
    }
    catch {
        throw "Failed to query GitHub releases: $($_.Exception.Message)"
    }
}

$release = if ($Version -eq 'latest') {
    Get-Releases "$releaseApi/latest"
}
else {
    $tag = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
    Get-Releases "$releaseApi/tags/$tag"
}
Write-Host "[setup] Release: $($release.tag_name)"

$assetName = if ($IsWindows) {
    ($release.assets | Where-Object { $_.name -match 'windows-x64\.zip$' } | Select-Object -First 1).name
}
else {
    ($release.assets | Where-Object { $_.name -match 'linux-x86_64\.tar\.xz$' } | Select-Object -First 1).name
}
if (-not $assetName) {
    throw "No matching release asset found for $(if ($IsWindows) { 'Windows (windows-x64.zip)' } else { 'Linux (linux-x86_64.tar.xz)' })."
}

# Default locations
if (-not $InstallDir) {
    if ($env:DOSBOX_AUTOMATION_INSTALL_DIR) { $InstallDir = $env:DOSBOX_AUTOMATION_INSTALL_DIR }
    elseif ($IsWindows) {
        $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME 'AppData\Local' }
        $InstallDir = Join-Path $base 'dosbox-agent-tools\dosbox-automation'
    }
    else {
        $base = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local\share' }
        $InstallDir = Join-Path $base 'dosbox-agent-tools\dosbox-automation'
    }
}
if (-not $ConfigDir) {
    if ($env:DOSBOX_AUTOMATION_CONF_DIR) { $ConfigDir = $env:DOSBOX_AUTOMATION_CONF_DIR }
    elseif ($env:XDG_CONFIG_HOME) { $ConfigDir = Join-Path $env:XDG_CONFIG_HOME 'dosbox-automation' }
    elseif ($IsWindows) {
        $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME 'AppData\Local' }
        $ConfigDir = Join-Path $base 'dosbox-automation'
    }
    else {
        $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
        $ConfigDir = Join-Path $base 'dosbox-automation'
    }
}

$InstallDir = [System.IO.Path]::GetFullPath($InstallDir)
$ConfigDir = [System.IO.Path]::GetFullPath($ConfigDir)
Write-Host "[setup] Install dir: $InstallDir"
Write-Host "[setup] Config dir : $ConfigDir (dosbox-automation primary config)"

# Existing install? Refuse to clobber unless -Force
$binaryCandidate = if ($IsWindows) { Join-Path $InstallDir 'dosbox.exe' } else { Join-Path $InstallDir 'dosbox' }
if ((Test-Path -LiteralPath $binaryCandidate) -and -not $Force) {
    Write-Warning "dosbox-automation already installed at $binaryCandidate. Pass -Force to reinstall."
    $existing = $binaryCandidate
}
else {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    $asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    $dl = Join-Path $env:TEMP $assetName
    Write-Host "[setup] Downloading $($asset.browser_download_url)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dl
    Write-Host "[setup] Downloaded $([math]::Round((Get-Item -LiteralPath $dl).Length / 1MB, 1)) MB"

    $tmp = Join-Path $env:TEMP ("dosbox-agent-tools-extract-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        if ($IsWindows) {
            Expand-Archive -LiteralPath $dl -DestinationPath $tmp
        }
        else {
            & tar -xf $dl -C $tmp
            if ($LASTEXITCODE -ne 0) { throw "tar extraction failed (exit $LASTEXITCODE)" }
        }
        $top = Get-ChildItem -LiteralPath $tmp -Directory | Select-Object -First 1
        $exe = if ($IsWindows) { 'dosbox.exe' } else { 'dosbox' }
        $found = Get-ChildItem -LiteralPath $tmp -Recurse -Filter $exe -File |
            Where-Object { $_.FullName -notmatch '\\Resources\\|/Resources/' } |
            Select-Object -First 1
        if (-not $found) { throw "Could not find $exe in the extracted archive." }
        $target = Join-Path $InstallDir $exe
        if ($top -and (Get-ChildItem -LiteralPath $top.FullName | Measure-Object).Count -gt 0) {
            Copy-Item -Path (Join-Path $top.FullName '*') -Destination $InstallDir -Recurse -Force
        }
        else {
            Copy-Item -Path (Join-Path $tmp '*') -Destination $InstallDir -Recurse -Force
        }
        $binaryCandidate = $target
    }
    finally {
        Remove-Item -LiteralPath $dl -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $binaryCandidate)) {
    throw "dosbox binary not found after install at $binaryCandidate"
}
Write-Host "[setup] Binary: $binaryCandidate"

# Primary dosbox-automation config (webserver + token file + mount bases)
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
$conf = Join-Path $ConfigDir 'dosbox-automation.conf'
$bases = @($InstallDir) + @($MountBase) | Select-Object -Unique
$confText = @(
    '[webserver]'
    'webserver_enabled = on'
    'webserver_bind_address = 127.0.0.1'
    'webserver_port = 8386'
    'webserver_allow_remote = off'
    'webserver_token_file = on'
    'webserver_osd = on'
    ('mount_allowed_bases = ' + ($bases -join ';'))
    ('mount_allowed_image_roots = ' + ($bases -join ';'))
    ''
    '[autoexec]'
    ''
) -join [Environment]::NewLine
Set-Content -LiteralPath $conf -Value $confText -Encoding ascii
Write-Host "[setup] Wrote primary config: $conf"

# Module config.json (points the module at the binary, token file, and base URL)
if ($env:DOSBOX_AUTOMATION_CONF) {
    $moduleConf = [System.IO.Path]::GetFullPath($env:DOSBOX_AUTOMATION_CONF)
    New-Item -ItemType Directory -Path (Split-Path -Parent $moduleConf) -Force | Out-Null
}
else {
    $moduleConfDir = if ($IsWindows) {
        $base = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $HOME 'AppData\Roaming' }
        Join-Path $base 'dosbox-agent-tools'
    }
    else {
        $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
        Join-Path $base 'dosbox-agent-tools'
    }
    New-Item -ItemType Directory -Path $moduleConfDir -Force | Out-Null
    $moduleConf = Join-Path $moduleConfDir 'config.json'
}
$tokenFile = Join-Path $ConfigDir ('webserver' + [System.IO.Path]::DirectorySeparatorChar + 'api_token')
$json = @{
    baseUrl      = 'http://127.0.0.1:8386'
    dosboxBinary = $binaryCandidate
    tokenFile    = $tokenFile
} | ConvertTo-Json
Set-Content -LiteralPath $moduleConf -Value $json -Encoding utf8
Write-Host "[setup] Wrote module config: $moduleConf"
Write-Host "[setup] Token file will be: $tokenFile (created by dosbox-automation at startup)"

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'dosbox-agent-tools.psd1'
Write-Host ''
Write-Host 'Done. Next steps:'
Write-Host "    Import-Module $modulePath"
Write-Host '    $s = Start-DosboxSession'
Write-Host '    Mount-DosboxDirectory -Drive C -HostPath <some-dir>'
Write-Host '    Wait-DosboxShell'
Write-Host '    Stop-DosboxSession'
Write-Host ''
Write-Host 'To allow mounts/swaps under extra directories, re-run with -MountBase <dir> or edit'
Write-Host "mount_allowed_bases / mount_allowed_image_roots in $conf (requires restart)."