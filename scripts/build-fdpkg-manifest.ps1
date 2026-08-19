<#
    build-fdpkg-manifest.ps1
    Generate a fdcli fdpkg.toml manifest from a directory of installed DOS files.

    Usage:
        pwsh scripts/build-fdpkg-manifest.ps1 `
            -SrcDir <path-to-installed-files> `
            -Name agenda -Version 2.0 -Group apps `
            -Title 'Lotus Agenda' `
            -Description 'Personal information manager.' `
            -Summary 'Lotus Agenda 2.0 ...' `
            -Author 'Lotus Development Corporation' `
            -LinkName AGENDA -LinkTarget AGENDA.EXE

    Every file under SrcDir becomes a [[files]] entry with destination
    "APPS/<NAME>/<relative 8.3 path>". Use -Exclude to skip artifacts.
    Path separators are normalized to '/' for fdcli.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SrcDir,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Group,
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$Summary,
    [Parameter(Mandatory = $true)][string]$Author,
    [string]$License = 'Commercial',
    [string]$Platforms = 'DOS',
    [Parameter(Mandatory = $true)][string]$LinkName,
    [Parameter(Mandatory = $true)][string]$LinkTarget,
    [string[]]$Exclude = @('AGTMP*.TMP'),
    [string]$OutFile = $null
)

$ErrorActionPreference = 'Stop'
if (-not $OutFile) { $OutFile = Join-Path (Split-Path -Parent $SrcDir) 'fdpkg.toml' }

$destPrefix = "$($Group.ToUpper())/$($Name.ToUpper())"

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("name = `"$Name`"")
[void]$sb.AppendLine("version = `"$Version`"")
[void]$sb.AppendLine("group = `"$Group`"")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("title = `"$Title`"")
[void]$sb.AppendLine("description = `"$Description`"")
[void]$sb.AppendLine("summary = `"$Summary`"")
[void]$sb.AppendLine("author = `"$Author`"")
[void]$sb.AppendLine("license = `"$License`"")
[void]$sb.AppendLine("platforms = `"$Platforms`"")

$files = Get-ChildItem -LiteralPath $SrcDir -Recurse -File |
    Where-Object {
        $rel = $_.FullName.Substring($SrcDir.Length).TrimStart('\', '/')
        $rel -notmatch (($Exclude | ForEach-Object { "^(?:[^\\/]*[\\/])*$($_ -replace '\.','\.' -replace '\*','[^\\/]*')$" }) -join '|')
    } |
    Sort-Object FullName

foreach ($f in $files) {
    $rel = $f.FullName.Substring($SrcDir.Length).TrimStart('\', '/')
    $relSrc = $rel -replace '\\', '/'
    $dest = ($destPrefix + '/' + $rel) -replace '\\', '/'
    [void]$sb.AppendLine("[[files]]")
    [void]$sb.AppendLine("source = `"src/$relSrc`"")
    [void]$sb.AppendLine("destination = `"$dest`"")
}

[void]$sb.AppendLine("[[links]]")
[void]$sb.AppendLine("name = `"$LinkName`"")
[void]$sb.AppendLine("target = `"$destPrefix/$LinkTarget`"")

$content = $sb.ToString()
Set-Content -LiteralPath $OutFile -Value $content -Encoding utf8
Write-Host "Wrote $OutFile with $($files.Count) files ($([math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)) MB)."
Write-Host "Link: $LinkName -> $destPrefix/$LinkTarget"