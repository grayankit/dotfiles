#requires -Version 5.1
# Recreate Start Menu shortcuts + WSL launchers without reinstalling the box.
# Run in PowerShell:  .\fix-neocolab-shortcuts.ps1

$ErrorActionPreference = "Stop"
$distro = "Ubuntu"

function WslText([string[]] $WslArgs) {
    $raw = & wsl.exe @WslArgs
    if ($null -eq $raw) { return @() }
    @($raw | ForEach-Object { ($_ -replace "`0", "").Trim() } | Where-Object { $_ })
}

function Write-WslScript([string] $Name, [string] $Body) {
    $unix = ($Body -replace "`r`n", "`n") -replace "`r", "`n"
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($unix))
    & wsl.exe -d $distro -- bash -c "echo $b64 | base64 -d > ~/.local/bin/$Name && chmod +x ~/.local/bin/$Name"
    if ($LASTEXITCODE -ne 0) { throw "failed to write ~/.local/bin/$Name" }
}

$neo = @'
#!/usr/bin/env bash
set -eu
export PATH="${HOME}/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PULSE_SERVER="${PULSE_SERVER:-unix:/mnt/wslg/PulseServer}"
export ELECTRON_OZONE_PLATFORM_HINT=x11
LOG="${HOME}/.local/share/distrobox/neocolab/launch.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "$(date -Iseconds) neo-browser"
if [ ! -t 0 ] && command -v script >/dev/null 2>&1; then
  exec script -qefc "$(printf '%q ' "${HOME}/.local/bin/neocolab-box" run Neo-Browser.AppImage --appimage-extract-and-run "$@")" /dev/null
fi
exec "${HOME}/.local/bin/neocolab-box" run Neo-Browser.AppImage --appimage-extract-and-run "$@"
'@

$chrome = @'
#!/usr/bin/env bash
set -eu
export PATH="${HOME}/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PULSE_SERVER="${PULSE_SERVER:-unix:/mnt/wslg/PulseServer}"
export ELECTRON_OZONE_PLATFORM_HINT=x11
LOG="${HOME}/.local/share/distrobox/neocolab/chrome-launch.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "$(date -Iseconds) neocolab-chrome"
if [ ! -t 0 ] && command -v script >/dev/null 2>&1; then
  exec script -qefc "$(printf '%q ' "${HOME}/.local/bin/neocolab-box" run google-chrome-stable --no-first-run --no-default-browser-check "$@")" /dev/null
fi
exec "${HOME}/.local/bin/neocolab-box" run google-chrome-stable --no-first-run --no-default-browser-check "$@"
'@

Write-Host "Updating WSL launchers..."
Write-WslScript "neo-browser" $neo
Write-WslScript "neocolab-chrome" $chrome

$linuxHome = (WslText @("-d", $distro, "-e", "printenv", "HOME") | Select-Object -First 1)
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

Write-Host "Done. Shortcuts in: $startDir"
Write-Host "Test: wsl -d $distro -e $linuxHome/.local/bin/neo-browser"
Write-Host "Log:  wsl -d $distro -- cat $linuxHome/.local/share/distrobox/neocolab/launch.log"
