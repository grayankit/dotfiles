#requires -Version 5.1
<#
.SYNOPSIS
  Upgrade Neo Browser inside WSL2 Ubuntu.

.EXAMPLE
  .\update-neocolab-wsl.ps1 .\Neo-Browser-2.1.0.AppImage
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $AppImage
)

$ErrorActionPreference = "Stop"
$distro = "Ubuntu"

function Die([string] $Message) {
    Write-Host "error: $Message" -ForegroundColor Red
    exit 1
}

function WslText([string[]] $WslArgs) {
    $raw = & wsl.exe @WslArgs 2>$null
    if ($null -eq $raw) { return @() }
    @($raw | ForEach-Object { ($_ -replace "`0", "").Trim() } | Where-Object { $_ })
}

$resolved = Resolve-Path -LiteralPath $AppImage -ErrorAction SilentlyContinue
if (-not $resolved) { Die "no such file: $AppImage" }
$winPath = $resolved.Path
if ($winPath -notmatch '\.AppImage$') { Die "expected an .AppImage file: $winPath" }

$names = WslText @("-l", "-q")
if ($names -notcontains $distro) { Die "WSL distro '$distro' not found" }

$wslApp = (WslText @("-d", $distro, "-e", "wslpath", "-a", $winPath) | Select-Object -First 1)
if (-not $wslApp) { Die "wslpath failed for $winPath" }

Write-Host "Upgrading Neo Browser inside $distro..."
Write-Host "AppImage: $wslApp"
Write-Host ""

& wsl.exe -d $distro -e /home/$((WslText @("-d", $distro, "-e", "id", "-un") | Select-Object -First 1))/.local/bin/neocolab-box upgrade $wslApp

if ($LASTEXITCODE -ne 0) { Die "upgrade failed (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "Done. Launch with:"
Write-Host "  wsl -d $distro -e /home/$((WslText @("-d", $distro, "-e", "id", "-un") | Select-Object -First 1))/.local/bin/neo-browser"
