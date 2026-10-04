#requires -Version 5.1
<#
.SYNOPSIS
  Fresh-install Neo Browser (NeoColab) on Windows via WSL2 Ubuntu + Distrobox + Podman.

.EXAMPLE
  .\install-neocolab.ps1 .\Neo-Browser-2.0.9.AppImage

Keep this file next to install-neocolab-wsl.sh.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $AppImage
)

$ErrorActionPreference = "Stop"

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

Write-Host "NeoColab Windows installer (WSL2 + Distrobox + Podman)"
Write-Host "AppImage: $winPath"
Write-Host ""

$wslOk = $false
try {
    $null = & wsl.exe -l -q 2>$null
    if ($LASTEXITCODE -eq 0) { $wslOk = $true }
} catch {
    $wslOk = $false
}

if (-not $wslOk) {
    Write-Host "WSL is not installed. Installing Ubuntu (a reboot may be required)..."
    Write-Host "After reboot: open Ubuntu once to create a user, then re-run this script."
    & wsl.exe --install -d Ubuntu
    exit 0
}

$names = WslText @("-l", "-q")
$distro = $names | Where-Object { $_ -match '^Ubuntu' } | Select-Object -First 1
if (-not $distro) { $distro = $names | Select-Object -First 1 }
if (-not $distro) {
    Write-Host "No WSL distro found. Installing Ubuntu..."
    & wsl.exe --install -d Ubuntu
    Write-Host "Open Ubuntu once to create a user, then re-run this script."
    exit 0
}

Write-Host "Using WSL distro: $distro"

$list = (WslText @("-l", "-v")) -join "`n"
if ($list -match [regex]::Escape($distro) -and $list -match "$([regex]::Escape($distro))\s+\S+\s+1\b") {
    Write-Host "Setting $distro to WSL 2..."
    & wsl.exe --set-version $distro 2
}

$linuxUser = (WslText @("-d", $distro, "-e", "id", "-un") | Select-Object -First 1)
if (-not $linuxUser -or $linuxUser -eq "root") {
    Die "Open '$distro' from the Start menu once to create your Linux user, then re-run."
}
Write-Host "Linux user: $linuxUser"

$pid1 = (WslText @("-d", $distro, "-e", "ps", "-p", "1", "-o", "comm=") | Select-Object -First 1)
if ($pid1 -notmatch 'systemd') {
    Write-Host "Enabling systemd (needed for Podman/Distrobox)..."
    & wsl.exe -d $distro -u root -- bash -c "printf '%s\n' '[boot]' 'systemd=true' > /etc/wsl.conf"
    Write-Host "Restarting WSL..."
    & wsl.exe --shutdown
    Start-Sleep -Seconds 10
    $pid1 = (WslText @("-d", $distro, "-e", "ps", "-p", "1", "-o", "comm=") | Select-Object -First 1)
    if ($pid1 -notmatch 'systemd') {
        Write-Host "warning: PID 1 is '$pid1' (wanted systemd). Continuing anyway."
    } else {
        Write-Host "systemd is running."
    }
}

$wslApp = (WslText @("-d", $distro, "-e", "wslpath", "-a", $winPath) | Select-Object -First 1)
if (-not $wslApp) { Die "wslpath failed for $winPath" }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$localSh = Join-Path $here "install-neocolab-wsl.sh"
$remoteSh = "/tmp/install-neocolab-wsl.sh"

if (Test-Path -LiteralPath $localSh) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $text = [IO.File]::ReadAllText($localSh) -replace "`r`n", "`n" -replace "`r", "`n"
    $tmpWin = Join-Path $env:TEMP "install-neocolab-wsl.lf.sh"
    [IO.File]::WriteAllText($tmpWin, $text, $utf8)
    $wslSh = (WslText @("-d", $distro, "-e", "wslpath", "-a", $tmpWin) | Select-Object -First 1)
    & wsl.exe -d $distro -- cp -- "$wslSh" $remoteSh
} else {
    Write-Host "install-neocolab-wsl.sh not next to this script; downloading from gist..."
    & wsl.exe -d $distro -- bash -c "curl -fsSL https://gist.githubusercontent.com/grayankit/af3021bc19d12c32f2888b7e540555af/raw/install-neocolab-wsl.sh | tr -d '\r' > $remoteSh"
}

if ($LASTEXITCODE -ne 0) { Die "failed to place install-neocolab-wsl.sh in WSL" }

& wsl.exe -d $distro -- bash -c "tr -d '\r' < $remoteSh > ${remoteSh}.lf && mv ${remoteSh}.lf $remoteSh && chmod +x $remoteSh"
Write-Host ""
Write-Host "Running installer inside $distro (first Distrobox init can take several minutes)..."
& wsl.exe -d $distro -- bash $remoteSh $wslApp
if ($LASTEXITCODE -ne 0) { Die "WSL installer failed (exit $LASTEXITCODE)" }

$linuxHome = (WslText @("-d", $distro, "-e", "printenv", "HOME") | Select-Object -First 1)
if (-not $linuxHome) { $linuxHome = "/home/$linuxUser" }

$startDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\NeoColab"
New-Item -ItemType Directory -Force -Path $startDir | Out-Null
$wsh = New-Object -ComObject WScript.Shell
$wslExe = Join-Path $env:SystemRoot "System32\wsl.exe"

function New-WslGuiShortcut([string] $Name, [string] $LinuxPath) {
    $lnk = $wsh.CreateShortcut((Join-Path $startDir "$Name.lnk"))
    $lnk.TargetPath = $wslExe
    $lnk.Arguments = "-d `"$distro`" -e `"$LinuxPath`""
    $lnk.WorkingDirectory = $env:USERPROFILE
    $lnk.WindowStyle = 1
    $lnk.Description = $Name
    $lnk.Save()
}

New-WslGuiShortcut "Neo Browser" "$linuxHome/.local/bin/neo-browser"
New-WslGuiShortcut "Chrome (NeoColab box)" "$linuxHome/.local/bin/neocolab-chrome"

Write-Host ""
Write-Host "Start Menu: search 'Neo Browser'  (folder: $startDir)"
Write-Host "Or:  wsl -d $distro -e $linuxHome/.local/bin/neo-browser"
Write-Host "Log: wsl -d $distro -- cat $linuxHome/.local/share/distrobox/neocolab/launch.log"
