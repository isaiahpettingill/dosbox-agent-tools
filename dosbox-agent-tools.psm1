#requires -Version 7
<#
    dosbox-agent-tools.psm1
    Cross-platform PowerShell driver for the dosbox-automation HTTP REST API.

    Works on Windows and Linux (PowerShell 7+ / pwsh). Start a headless emulator
    with Start-DosboxSession, then drive it:
      - Inject keyboard input (Send-DosboxText / Send-DosboxKey / Invoke-DosboxCommand)
      - Read the text-mode screen (Get-DosboxScreenText / Wait-DosboxScreenText)
      - Swap floppy/hard disk images (Set-DosboxDrive)
      - Mount host directories (Mount-DosboxDirectory)
      - Record input and video capture

    All input functions are automatically throttled per-session so the emulator's
    single replay queue is never overrun (no more "409 Replay already in progress").

    Where the module finds dosbox-automation (highest to lowest):
      1. Environment variables: DOSBOX_AUTOMATION_BIN, DOSBOX_AUTOMATION_TOKEN_FILE,
         DOSBOX_AUTOMATION_URL
      2. A JSON config file (path via DOSBOX_AUTOMATION_CONF, otherwise
         ~/.config/dosbox-agent-tools/config.json; %APPDATA% on Windows).
         Fields: dosboxBinary, tokenFile, baseUrl.
      3. Built-in defaults (baseUrl http://127.0.0.1:8386).

    Run scripts/setup-dosbox-automation.ps1 once to download dosbox-automation
    and write that config file for you.
#>

Set-StrictMode -Version Latest

$script:DefaultBaseUrl = 'http://127.0.0.1:8386'
$script:DefaultSession = $null
$script:DefaultMinGapMs = 250
$script:ResolvedConfig = $null

<#
.SYNOPSIS
    Locate the module config file, honoring the DOSBOX_AUTOMATION_CONF override.
#>
function Get-DosboxAgentConfigPath {
    if ($env:DOSBOX_AUTOMATION_CONF) { return $env:DOSBOX_AUTOMATION_CONF }
    if ($IsWindows) {
        $base = if ($env:APPDATA) { $env:APPDATA } else { Join-Path $HOME 'AppData\Roaming' }
    }
    else {
        $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    }
    return Join-Path $base 'dosbox-agent-tools\config.json'
}

<#
.SYNOPSIS
    Resolve module defaults from env vars, then the config file, then built-ins.
#>
function Get-DosboxAgentConfig {
    if ($null -ne $script:ResolvedConfig) { return $script:ResolvedConfig }
    $cfg = @{
        baseUrl   = $script:DefaultBaseUrl
        binary    = $null
        tokenFile = $null
    }
    $path = Get-DosboxAgentConfigPath
    if (Test-Path -LiteralPath $path) {
        try {
            $j = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            if ($j.baseUrl)   { $cfg.baseUrl = [string]$j.baseUrl }
            if ($j.dosboxBinary) { $cfg.binary = [string]$j.dosboxBinary }
            if ($j.tokenFile) { $cfg.tokenFile = [string]$j.tokenFile }
        }
        catch { Write-Warning "Could not parse config file '$path': $($_.Exception.Message)" }
    }
    if ($env:DOSBOX_AUTOMATION_URL)   { $cfg.baseUrl = $env:DOSBOX_AUTOMATION_URL }
    if ($env:DOSBOX_AUTOMATION_BIN)   { $cfg.binary = $env:DOSBOX_AUTOMATION_BIN }
    if ($env:DOSBOX_AUTOMATION_TOKEN_FILE) { $cfg.tokenFile = $env:DOSBOX_AUTOMATION_TOKEN_FILE }
    $script:ResolvedConfig = $cfg
    return $cfg
}

function Resolve-DosboxBinary {
    param([string]$BinaryPath)
    if ($BinaryPath) { return $BinaryPath }
    $bin = (Get-DosboxAgentConfig).binary
    if (-not $bin) {
        throw "dosbox-automation binary not configured. Run scripts/setup-dosbox-automation.ps1 once, or set DOSBOX_AUTOMATION_BIN."
    }
    return $bin
}

function Resolve-DosboxTokenFile {
    param([string]$TokenFile)
    if ($TokenFile) { return $TokenFile }
    $tf = (Get-DosboxAgentConfig).tokenFile
    if (-not $tf) {
        throw "dosbox-automation token file not configured. Run scripts/setup-dosbox-automation.ps1 once, or set DOSBOX_AUTOMATION_TOKEN_FILE."
    }
    return $tf
}

function Resolve-DosboxBaseUrl {
    param([string]$BaseUrl)
    if ($BaseUrl) { return $BaseUrl }
    return (Get-DosboxAgentConfig).baseUrl
}

function Resolve-Session {
    param(
        [Parameter(Mandatory = $false)]$Session
    )
    if ($null -eq $Session) { $Session = $script:DefaultSession }
    if ($null -eq $Session) {
        throw 'No DOSBox session. Call Start-DosboxSession first (or pass -Session).'
    }
    return $Session
}

<#
.SYNOPSIS
    Throttle input so the emulator's single replay queue never overruns.
.DESCRIPTION
    dosbox-automation feeds /input/type and /input/sequence through one queue; a
    send while the previous replay is still draining returns
    "409 Replay already in progress". Every input function calls this gate first.
    It sleeps until the previous send's busy window has elapsed (plus a small
    inter-send gap), then records how long THIS send will keep the emulator busy.
.PARAMETER CostMs
    How long this send will occupy the emulator (chars/cps for typing, the
    event timeline for key sequences). 0 = the send is effectively instant.
.PARAMETER MinGapMs
    Minimum time to wait between the previous send's busy window and this one.
    Defaults to the module-wide $script:DefaultMinGapMs (250ms).
#>
function Wait-DosboxInputGate {
    [CmdletBinding()]
    param(
        [double]$CostMs = 0,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        $Session = $null
    )
    $Session = Resolve-Session $Session
    $busy = $null
    if ($Session.PSObject.Properties['BusyUntil']) { $busy = $Session.BusyUntil }
    $leftMs = 0.0
    if ($null -ne $busy) {
        $leftMs = ($busy - (Get-Date)).TotalMilliseconds
    }
    if ($leftMs -gt 0) { Start-Sleep -Milliseconds ($leftMs + $MinGapMs) }
    elseif ($MinGapMs -gt 0) { Start-Sleep -Milliseconds $MinGapMs }
    $Session | Add-Member -NotePropertyName BusyUntil -NotePropertyValue ((Get-Date).AddMilliseconds($CostMs)) -Force
}

function Get-DosboxToken {
    param([Parameter(Mandatory = $true)][string]$TokenFile)
    if (-not (Test-Path -LiteralPath $TokenFile)) {
        throw "Token file not found: $TokenFile (is the webserver enabled?)"
    }
    return (Get-Content -LiteralPath $TokenFile -Raw).Trim()
}

function Invoke-DosboxApi {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')][string]$Method = 'GET',
        [object]$Body = $null,
        [string]$ContentType = 'application/json',
        [string]$Accept = 'application/json',
        [string]$OutFile = $null,
        [switch]$Raw,
        $Session = $null
    )
    $Session = Resolve-Session $Session
    $uri = "$($Session.BaseUrl)$Path"
    $headers = @{ Authorization = "Bearer $($Session.Token)" }
    if ($Accept) { $headers.Accept = $Accept }
    $params = @{
        Method  = $Method
        Uri     = $uri
        Headers = $headers
        TimeoutSec = 60
    }
    if ($null -ne $Body) { $params.ContentType = $ContentType; $params.Body = $Body }
    if ($OutFile) { $params.OutFile = $OutFile }
    try {
        if ($OutFile) {
            Invoke-WebRequest @params | Out-Null
            return $null
        }
        $resp = Invoke-RestMethod @params
        if ($Raw) { return $resp }
        return $resp
    }
    catch {
        $detail = ''
        if ($_.Exception.Response) {
            try {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.Content.ReadAsStream())
                $detail = $reader.ReadToEnd()
            }
            catch { }
        }
        if ($detail) { throw "$($_.Exception.Message) -- HTTP $([int]$_.Exception.Response.StatusCode): $detail" }
        throw
    }
}

function New-DosboxSessionObject {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][string]$BinaryPath,
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$TokenFile,
        [Parameter(Mandatory = $true)][string]$Token
    )
    return [pscustomobject]@{
        ProcessId = $Process.Id
        Process   = $Process
        BinaryPath = $BinaryPath
        BaseUrl   = $BaseUrl
        TokenFile = $TokenFile
        Token     = $Token
        StartedAt = Get-Date
    }
}

<#
.SYNOPSIS
    Attach to an already-running dosbox-automation instance.
.DESCRIPTION
    Builds a session object from the current token file and a running dosbox.exe
    process. Useful for connecting to a session that was started earlier (e.g. in
    a previous shell) instead of restarting the emulator.
.PARAMETER BaseUrl
    Base URL of the REST API. Defaults to http://127.0.0.1:8386.
.PARAMETER TokenFile
    Where the webserver writes the per-run bearer token.
.PARAMETER ProcessId
    The dosbox.exe PID. If omitted, the first running dosbox-automation process is used.
#>
function Connect-DosboxSession {
    [CmdletBinding()]
    param(
        [string]$BaseUrl = $null,
        [string]$TokenFile = $null,
        [int]$ProcessId = 0
    )
    $BaseUrl = Resolve-DosboxBaseUrl $BaseUrl
    $TokenFile = Resolve-DosboxTokenFile $TokenFile
    $token = Get-DosboxToken $TokenFile
    if ($ProcessId -eq 0) {
        $proc = Get-Process -Name 'dosbox' -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -like '*dosbox-automation*' } |
            Select-Object -First 1
        if ($null -eq $proc) {
            $proc = Get-Process -Name 'dosbox' -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($null -eq $proc) { throw 'No running dosbox.exe process found.' }
        $ProcessId = $proc.Id
    }
    $proc = Get-Process -Id $ProcessId -ErrorAction Stop
    $session = New-DosboxSessionObject -Process $proc -BinaryPath $proc.Path -BaseUrl $BaseUrl -TokenFile $TokenFile -Token $token
    $script:DefaultSession = $session
    return $session
}

<#
.SYNOPSIS
    Start a headless dosbox-automation instance and wait for its REST API.
.DESCRIPTION
    Launches dosbox.exe with SDL_VIDEODRIVER=dummy and --nolocalconf so only the
    primary config is used. The binary, token file, and base URL resolve from
    DOSBOX_AUTOMATION_* env vars, then the module config file, then built-ins.
    Polls the API until it responds, then caches the session.
.PARAMETER BinaryPath
    Path to dosbox.exe. Defaults to the configured binary.
.PARAMETER BaseUrl
    Base URL of the REST API. Defaults to the configured URL.
.PARAMETER TokenFile
    Where the webserver writes the per-run bearer token. Defaults to the
    configured token file.
.PARAMETER WorkingDirectory
    Working directory for the emulator process. Defaults to the binary's directory.
.PARAMETER ExtraArgs
    Extra command-line arguments passed to dosbox.exe.
.PARAMETER StartupTimeoutSec
    How long to wait for the API to respond.
.EXAMPLE
    $s = Start-DosboxSession
#>
function Start-DosboxSession {
    [CmdletBinding()]
    param(
        [string]$BinaryPath = $null,
        [string]$BaseUrl = $null,
        [string]$TokenFile = $null,
        [string]$WorkingDirectory = $null,
        [string[]]$ExtraArgs = @(),
        [int]$StartupTimeoutSec = 30
    )
    $BinaryPath = Resolve-DosboxBinary $BinaryPath
    $BaseUrl = Resolve-DosboxBaseUrl $BaseUrl
    $TokenFile = Resolve-DosboxTokenFile $TokenFile
    if (-not (Test-Path -LiteralPath $BinaryPath)) {
        throw "dosbox.exe not found: $BinaryPath"
    }
    if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path -Parent $BinaryPath }

    $old = $env:SDL_VIDEODRIVER
    $env:SDL_VIDEODRIVER = 'dummy'
    $oldTokenTime = $null
    if (Test-Path -LiteralPath $TokenFile) {
        $oldTokenTime = (Get-Item -LiteralPath $TokenFile).LastWriteTimeUtc
    }
    try {
        $args = @('--nolocalconf') + $ExtraArgs
        $proc = Start-Process -FilePath $BinaryPath -ArgumentList $args -WorkingDirectory $WorkingDirectory -PassThru
    }
    finally {
        if ($null -eq $old) { Remove-Item Env:SDL_VIDEODRIVER -ErrorAction SilentlyContinue }
        else { $env:SDL_VIDEODRIVER = $old }
    }

    $port = ([uri]$BaseUrl).Port
    $deadline = (Get-Date).AddSeconds($StartupTimeoutSec)
    $token = $null
    do {
        Start-Sleep -Milliseconds 500
        if ($proc.HasExited) {
            throw "dosbox.exe exited during startup (exit code $($proc.ExitCode)). Check the config at $TokenFile."
        }
        if (Test-Path -LiteralPath $TokenFile) {
            $t = (Get-Item -LiteralPath $TokenFile).LastWriteTimeUtc
            if ($null -eq $oldTokenTime -or $t -gt $oldTokenTime) {
                try { $token = Get-DosboxToken $TokenFile } catch { }
            }
        }
    } while ($null -eq $token -and (Get-Date) -lt $deadline)

    if ($null -eq $token) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        throw "Timed out waiting for the webserver token at $TokenFile."
    }

    $session = New-DosboxSessionObject -Process $proc -BinaryPath $BinaryPath -BaseUrl $BaseUrl -TokenFile $TokenFile -Token $token

    $deadline = (Get-Date).AddSeconds($StartupTimeoutSec)
    $ready = $false
    do {
        try {
            Invoke-DosboxApi -Path '/api/v1/dosbox/info' -Session $session | Out-Null
            $ready = $true
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    } while (-not $ready -and (Get-Date) -lt $deadline)

    if (-not $ready) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        throw "Timed out waiting for the REST API at $BaseUrl."
    }

    $script:DefaultSession = $session
    return $session
}

<#
.SYNOPSIS
    Gracefully stop the current (or given) DOSBox session.
.PARAMETER Force
    Kill the process if it does not exit within TimeoutSec.
.PARAMETER TimeoutSec
    Seconds to wait for graceful shutdown before force-killing.
#>
function Stop-DosboxSession {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 10,
        [switch]$Force,
        $Session = $null
    )
    $Session = Resolve-Session $Session
    try {
        Invoke-DosboxApi -Path '/api/v1/dosbox/shutdown' -Method POST -Session $Session | Out-Null
    }
    catch {
        if (-not $Force) { throw }
    }
    $proc = $Session.Process
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        $proc.Refresh()
    }
    if (-not $proc.HasExited) {
        if (-not $Force) { throw 'DOSBox did not shut down gracefully within the timeout. Pass -Force to kill it.' }
        Stop-Process -Id $proc.Id -Force
        $proc.WaitForExit(5000) | Out-Null
    }
    if ($null -ne $script:DefaultSession -and $script:DefaultSession.ProcessId -eq $proc.Id) {
        $script:DefaultSession = $null
    }
}

<#
.SYNOPSIS
    Return the current session object (or a specific one with -Session).
#>
function Get-DosboxSession {
    [CmdletBinding()]
    param($Session = $null)
    if ($null -eq $Session) { return $script:DefaultSession }
    return $Session
}

<#
.SYNOPSIS
    GET /api/v1/status
#>
function Get-DosboxStatus {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/status' -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/program/state
#>
function Get-DosboxProgramState {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/program/state' -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/dosbox/info
#>
function Get-DosboxInfo {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/dosbox/info' -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/video/text -- read the text-mode screen.
#>
function Get-DosboxScreenText {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/video/text' -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/video/frame/info -- frame metadata.
#>
function Get-DosboxFrameInfo {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/video/frame/info' -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/video/frame -- save a screenshot of the emulated screen.
.PARAMETER Format
    png, jpeg, or raw.
.PARAMETER Mode
    raw (emulator framebuffer) or rendered (as shown on screen).
.PARAMETER Quality
    JPEG quality 1-100.
#>
function Save-DosboxScreenshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$OutFile,
        [ValidateSet('png', 'jpeg', 'raw')][string]$Format = 'png',
        [ValidateSet('raw', 'rendered')][string]$Mode = 'raw',
        [int]$Quality = 98,
        $Session = $null
    )
    $path = "/api/v1/video/frame?format=$Format&mode=$Mode"
    if ($Format -eq 'jpeg') { $path += "&quality=$Quality" }
    $accept = switch ($Format) {
        'png'  { 'image/png' }
        'jpeg' { 'image/jpeg' }
        'raw'  { 'application/octet-stream' }
    }
    Invoke-DosboxApi -Path $path -Accept $accept -OutFile $OutFile -Session $Session
    return (Get-Item -LiteralPath $OutFile)
}

function Normalize-KeyName {
    param([Parameter(Mandatory = $true)][string]$Key)
    $k = $Key.Trim()
    if (-not $k.StartsWith('KBD_')) { $k = "KBD_$k" }
    return $k
}

<#
.SYNOPSIS
    POST /api/v1/input/type -- type a string into the emulator.
.PARAMETER Text
    String to type (up to 4096 chars).
.PARAMETER Cps
    Characters per second (default 30).
#>
function Send-DosboxText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [int]$Cps = 30,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        $Session = $null
    )
    $costMs = if ($Cps -gt 0) { ($Text.Length / $Cps) * 1000 } else { 0 }
    Wait-DosboxInputGate -CostMs $costMs -MinGapMs $MinGapMs -Session $Session
    $body = @{ text = $Text; cps = $Cps } | ConvertTo-Json
    Invoke-DosboxApi -Path '/api/v1/input/type' -Method POST -Body $body -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/input/sequence -- press and release named keys.
.PARAMETER Key
    Key name(s) with or without the KBD_ prefix, e.g. 'enter', 'f1', 'KBD_esc'.
    Multiple keys are sent in order.
.PARAMETER HoldMs
    Milliseconds the key stays pressed.
.PARAMETER GapMs
    Milliseconds between key events.
.PARAMETER DelayBeforeMs
    Optional leading delay.
.EXAMPLE
    Send-DosboxKey -Key @('enter') -DelayBeforeMs 2000
#>
function Send-DosboxKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string[]]$Key,
        [double]$HoldMs = 50,
        [double]$GapMs = 30,
        [double]$DelayBeforeMs = 0,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        $Session = $null
    )
    $events = [System.Collections.Generic.List[object]]::new()
    $t = $DelayBeforeMs
    foreach ($k in $Key) {
        $name = Normalize-KeyName $k
        $events.Add([pscustomobject]@{ type = 'key'; key = $name; pressed = $true;  t = $t })
        $t += $HoldMs
        $events.Add([pscustomobject]@{ type = 'key'; key = $name; pressed = $false; t = $t })
        $t += $GapMs
    }
    $costMs = ($events[-1].t) + $HoldMs + $GapMs
    Wait-DosboxInputGate -CostMs $costMs -MinGapMs $MinGapMs -Session $Session
    $body = @{ events = $events.ToArray() } | ConvertTo-Json -Depth 4
    Invoke-DosboxApi -Path '/api/v1/input/sequence' -Method POST -Body $body -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/input/sequence -- send a hand-built event array.
.PARAMETER Events
    Array of event objects with type/key/pressed/t as documented by the REST API.
#>
function Send-DosboxSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object[]]$Events,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        $Session = $null
    )
    $maxT = ($Events | Measure-Object -Property t -Maximum).Maximum
    $costMs = if ($null -ne $maxT) { [double]$maxT + 50 } else { 0 }
    Wait-DosboxInputGate -CostMs $costMs -MinGapMs $MinGapMs -Session $Session
    $body = @{ events = $Events } | ConvertTo-Json -Depth 6
    Invoke-DosboxApi -Path '/api/v1/input/sequence' -Method POST -Body $body -Session $Session
}

<#
.SYNOPSIS
    Type a DOS command at the shell and press Enter.
.DESCRIPTION
    Sends <Command> via /input/type then Enter via /input/sequence. The input
    gate throttles automatically, so Enter is never injected while the text is
    still being replayed (that used to cause "409 Replay already in progress").
    Use Wait-DosboxScreenText / Wait-DosboxShell / Wait-DosboxPrompt afterwards.
.PARAMETER NoEnter
    Type the command but do not press Enter.
#>
function Invoke-DosboxCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [int]$Cps = 60,
        [switch]$NoEnter,
        [switch]$PressEnter,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        $Session = $null
    )
    Send-DosboxText -Text $Command -Cps $Cps -MinGapMs $MinGapMs -Session $Session | Out-Null
    if ($NoEnter) { return }
    Send-DosboxKey -Key 'enter' -MinGapMs $MinGapMs -Session $Session | Out-Null
}

<#
.SYNOPSIS
    POST /api/v1/drive/swap -- swap the disk image on a drive letter.
.PARAMETER Drive
    Drive letter (e.g. 'A').
.PARAMETER Image
    Absolute host path to the disk image.
#>
function Set-DosboxDrive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Drive,
        [Parameter(Mandatory = $true)][string]$Image,
        $Session = $null
    )
    $body = @{ drive = $Drive; image = $Image } | ConvertTo-Json
    Invoke-DosboxApi -Path '/api/v1/drive/swap' -Method POST -Body $body -Session $Session
}

<#
.SYNOPSIS
    Mount a host directory inside DOSBox (DOSBox 'mount' internal command).
.DESCRIPTION
    Types 'mount <Drive>: "<HostPath>"' at the Z: shell prompt. The host path must
    be under a directory allowed by mount_allowed_bases in the primary config.
    Throws if the mount is refused (path not allowed, already used, or invalid).
.PARAMETER Drive
    Drive letter to map (e.g. 'C').
.PARAMETER HostPath
    Absolute host directory path.
.PARAMETER NoVerify
    Skip waiting for the mount result text.
#>
function Mount-DosboxDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Drive,
        [Parameter(Mandatory = $true)][string]$HostPath,
        [int]$Cps = 60,
        [double]$MinGapMs = $script:DefaultMinGapMs,
        [switch]$NoVerify,
        $Session = $null
    )
    $cmd = 'mount {0}: "{1}"' -f $Drive, $HostPath
    Invoke-DosboxCommand -Command $cmd -Cps $Cps -MinGapMs $MinGapMs -Session $Session | Out-Null
    if ($NoVerify) { return }
    $screen = Wait-DosboxScreenText -Match 'mounted\s+as|already\s+mounted|not a directory|Access denied|Invalid' -TimeoutSec 10 -PollMs 200 -Session $Session
    if ($screen -match 'not a directory|Access denied|Invalid') {
        throw "Mount of '$HostPath' as $Drive`: failed. Screen:$screen"
    }
}

<#
.SYNOPSIS
    POST /api/v1/mount/lock -- lock mounts (one-way, until restart).
#>
function Lock-DosboxMounts {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/mount/lock' -Method POST -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/mount/lock -- check mount lock state.
#>
function Get-DosboxMountLock {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/mount/lock' -Session $Session
}

<#
.SYNOPSIS
    Wait until the DOS shell (command.com) is the active program.
#>
function Wait-DosboxShell {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 30,
        [int]$PollMs = 300,
        $Session = $null
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $st = Get-DosboxStatus -Session $Session
        if ($st.is_shell) { return $st }
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for the DOS shell (last: $($st.canonical_name))."
}

<#
.SYNOPSIS
    Wait until status.program / canonical_name matches a regex and is not the shell.
.PARAMETER Match
    Regex matched against program name (e.g. 'INSTALL').
#>
function Wait-DosboxProgram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Match,
        [int]$TimeoutSec = 30,
        [int]$PollMs = 300,
        $Session = $null
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $st = Get-DosboxStatus -Session $Session
        if (-not $st.is_shell -and $st.program -match $Match) { return $st }
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for program '$Match' (last: $($st.program))."
}

<#
.SYNOPSIS
    Poll the text-mode screen until a regex matches.
.PARAMETER Match
    Regex to search for in the screen text.
.PARAMETER NotMatch
    Optional regex that aborts with an error if it appears (e.g. error dialogs).
.PARAMETER FailIfExit
    If the emulator process exits before a match, throw.
.EXAMPLE
    Wait-DosboxScreenText -Match 'Installation complete' -TimeoutSec 120
#>
function Wait-DosboxScreenText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Match,
        [string]$NotMatch = $null,
        [int]$TimeoutSec = 60,
        [int]$PollMs = 400,
        [switch]$FailIfExit,
        $Session = $null
    )
    $Session = Resolve-Session $Session
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $last = ''
    do {
        if ($FailIfExit -and $Session.Process.HasExited) {
            throw "DOSBox exited while waiting for '$Match'."
        }
        $last = (Invoke-DosboxApi -Path '/api/v1/video/text' -Session $Session).text
        if ($last -match $Match) { return $last }
        if ($NotMatch -and $last -match $NotMatch) {
            throw "Screen matched abort pattern '$NotMatch':`n$last"
        }
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for '$Match'. Last screen:`n$last"
}

<#
.SYNOPSIS
    Wait until the screen text stops changing (command output finished).
.DESCRIPTION
    Reads the screen twice PollMs apart; returns once both reads are identical,
    or throws on TimeoutSec.
#>
function Wait-DosboxScreenStable {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 30,
        [int]$PollMs = 500,
        $Session = $null
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $prev = $null
    do {
        $cur = (Invoke-DosboxApi -Path '/api/v1/video/text' -Session $Session).text
        if ($null -ne $prev -and $cur -eq $prev) { return $cur }
        $prev = $cur
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)
    return $prev
}

<#
.SYNOPSIS
    Wait until the input replay queue has drained (all sends fully delivered).
.DESCRIPTION
    Waits until the session's input gate reports no outstanding replay. Handy
    before a screenshot, or before a step that must not race keystrokes (e.g.
    swapping a disk image).
#>
function Wait-DosboxInputIdle {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 30,
        [int]$PollMs = 200,
        $Session = $null
    )
    $Session = Resolve-Session $Session
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $busy = $Session.PSObject.Properties['BusyUntil']
        if (-not $busy -or $busy.Value -le (Get-Date)) { return }
        Start-Sleep -Milliseconds $PollMs
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for the input queue to drain (busy until $($busy.Value))."
}

<#
.SYNOPSIS
    Wait until a DOS command prompt is visible on the screen.
.DESCRIPTION
    Matches a drive-letter prompt such as Z:\> or C:\FPD26>. Useful after
    commands that should end by returning to the shell (INSTALL.COM finishing,
    DIR output scrolling by, a mount completing).
.PARAMETER Match
    Optional override regex for the prompt; defaults to a drive-letter prompt.
#>
function Wait-DosboxPrompt {
    [CmdletBinding()]
    param(
        [string]$Match = '[A-Z]:\\?>',
        [int]$TimeoutSec = 30,
        [int]$PollMs = 300,
        [switch]$FailIfExit,
        $Session = $null
    )
    Wait-DosboxScreenText -Match $Match -TimeoutSec $TimeoutSec -PollMs $PollMs -FailIfExit:$FailIfExit -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/input/record/start
#>
function Start-DosboxInputRecording {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/input/record/start' -Method POST -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/input/record/stop -- returns the recorded events.
#>
function Stop-DosboxInputRecording {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/input/record/stop' -Method POST -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/input/record/status
#>
function Get-DosboxInputRecordingStatus {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/input/record/status' -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/capture/video/start -- record the screen to a ZMBV AVI.
.PARAMETER Mode
    raw (framebuffer) or rendered (as shown on screen).
#>
function Start-DosboxVideoCapture {
    [CmdletBinding()]
    param(
        [ValidateSet('raw', 'rendered')][string]$Mode = 'raw',
        $Session = $null
    )
    $body = @{ mode = $Mode } | ConvertTo-Json
    Invoke-DosboxApi -Path '/api/v1/capture/video/start' -Method POST -Body $body -Session $Session
}

<#
.SYNOPSIS
    POST /api/v1/capture/video/stop
#>
function Stop-DosboxVideoCapture {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/capture/video/stop' -Method POST -Session $Session
}

<#
.SYNOPSIS
    GET /api/v1/capture/video/status
#>
function Get-DosboxVideoCaptureStatus {
    [CmdletBinding()]
    param($Session = $null)
    Invoke-DosboxApi -Path '/api/v1/capture/video/status' -Session $Session
}

Export-ModuleMember -Function @(
'Start-DosboxSession',
    'Stop-DosboxSession',
    'Get-DosboxSession',
    'Connect-DosboxSession',
    'Get-DosboxStatus',
    'Get-DosboxProgramState',
    'Get-DosboxInfo',
    'Get-DosboxScreenText',
    'Get-DosboxFrameInfo',
    'Save-DosboxScreenshot',
    'Send-DosboxText',
    'Send-DosboxKey',
    'Send-DosboxSequence',
    'Invoke-DosboxCommand',
    'Set-DosboxDrive',
    'Mount-DosboxDirectory',
    'Lock-DosboxMounts',
    'Get-DosboxMountLock',
    'Wait-DosboxShell',
    'Wait-DosboxProgram',
    'Wait-DosboxScreenText',
    'Wait-DosboxScreenStable',
    'Wait-DosboxInputIdle',
    'Wait-DosboxPrompt',
    'Start-DosboxInputRecording',
    'Stop-DosboxInputRecording',
    'Get-DosboxInputRecordingStatus',
    'Start-DosboxVideoCapture',
    'Stop-DosboxVideoCapture',
    'Get-DosboxVideoCaptureStatus'
)
