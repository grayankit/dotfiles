#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

; Chars per chunk: bigger = faster, smaller = snappier Backspace abort
global CHUNK := 50

!v:: {
    text := A_Clipboard
    if (text = "")
        return

    ; One Enter per line (CRLF would otherwise insert a blank line)
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    text := RTrim(text, "`n")

    KeyWait "Alt", "T0.5"

    keys := "{Blind}{Alt up}{Ctrl up}{Shift up}{LWin up}{RWin up}"
    Loop Parse text {
        ch := A_LoopField
        if (ch = "`n") {
            keys .= "{Enter}"
            continue
        }
        if (ch = "`t") {
            keys .= "{Tab}"
            continue
        }

        scan := DllCall("user32\VkKeyScanW", "UShort", Ord(ch), "Short")
        if (scan = -1) {
            keys .= "{U+" Format("{:04X}", Ord(ch)) "}"
            continue
        }

        vk := Format("{:02X}", scan & 0xFF)
        if (scan & 0x100)
            keys .= "+{vk" vk "}"
        else
            keys .= "{vk" vk "}"
    }

    Sleep 10

    pos := 1
    len := StrLen(keys)
    while (pos <= len) {
        if GetKeyState("Backspace", "P")
            return

        ; Do not split inside a {token}
        end := pos + CHUNK - 1
        if (end < len) {
            while (end > pos && SubStr(keys, end, 1) != "}")
                end--
            if (end = pos)
                end := pos + CHUNK - 1
        } else
            end := len

        Send SubStr(keys, pos, end - pos + 1)
        pos := end + 1
    }
}
