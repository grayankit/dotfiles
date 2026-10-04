#requires -Version 5.1
# Type clipboard as keystrokes (like Linux writec-clipboard.sh).
# Quotes and special chars are preserved; SendKeys metachars are escaped.
param(
    [int] $DelayMs = 100
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

Start-Sleep -Milliseconds $DelayMs

$text = Get-Clipboard -Raw -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($text)) {
    exit 0
}

# CRLF -> LF for SendKeys; strip trailing newline like wl-paste --no-newline
$text = $text -replace "`r`n", "`n" -replace "`r", "`n"
$text = $text.TrimEnd("`n")

# Escape SendKeys specials so they type literally (+ ^ % ~ () {} [] ")
$escaped = [regex]::Replace($text, '[+^%~(){}\[\]"]', { param($m) '{' + $m.Value + '}' })
# Newlines become Enter
$escaped = $escaped -replace "`n", '{ENTER}'

[Windows.Forms.SendKeys]::SendWait($escaped)
