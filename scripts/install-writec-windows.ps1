#requires -Version 5.1
<#
.SYNOPSIS
  Install Ctrl+Alt+V Start Menu shortcut for writec-clipboard.ps1 (native Windows hotkey).

.EXAMPLE
  .\install-writec-windows.ps1
  .\install-writec-windows.ps1 -Uninstall
#>
param(
    [switch] $Uninstall
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps1 = Join-Path $scriptDir 'writec-clipboard.ps1'
if (-not (Test-Path -LiteralPath $ps1)) {
    Write-Host "error: missing $ps1" -ForegroundColor Red
    exit 1
}

$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$lnkPath = Join-Path $programs 'writec-clipboard.lnk'

if ($Uninstall) {
    if (Test-Path -LiteralPath $lnkPath) {
        Remove-Item -LiteralPath $lnkPath -Force
        Write-Host "Removed $lnkPath"
    } else {
        Write-Host "Nothing to remove."
    }
    exit 0
}

$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut($lnkPath)
$sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$sc.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ps1`""
$sc.WorkingDirectory = $scriptDir
$sc.WindowStyle = 7
$sc.Description = 'Type clipboard as keystrokes'
$sc.Hotkey = 'Ctrl+Alt+V'
$sc.Save()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

Write-Host "Installed: $lnkPath"
Write-Host "Hotkey:    Ctrl+Alt+V"
Write-Host ""
Write-Host "Copy text, focus a field, press Ctrl+Alt+V."
Write-Host "If the hotkey does nothing: open Start, search 'writec-clipboard', right-click > Open file location, Properties > Shortcut key, set Ctrl+Alt+V, OK."
