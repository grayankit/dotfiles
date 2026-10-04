#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

locked := false
lockedHwnd := 0
savedGestures := Map()
savedTouchGesture := unset
ptpKey := "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PrecisionTouchPad"
deskKey := "HKCU\Control Panel\Desktop"
gestureNames := [
    "ThreeFingerSlideEnabled",
    "FourFingerSlideEnabled",
    "ThreeFingerTapEnabled",
    "FourFingerTapEnabled",
]

A_IconTip := "NeoColab kiosk  |  Ctrl+Alt+L toggle"
OnExit(Cleanup)

IsTargetWindow(hwnd) {
    if !hwnd
        return false
    try {
        title := WinGetTitle(hwnd)
        return title ~= "i)Neo Browser|Google Chrome|Chromium"
    } catch {
        return false
    }
}

NotifyTouchpadSettings() {
    ; Windows 11 caches Precision TouchPad settings in Explorer.
    ; Registry writes do nothing until IImmersiveSettingsCache is notified.
    try {
        sp := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{6D5140C1-7436-11CE-8034-00AA006009FA}")
        sid := Buffer(16), iid := Buffer(16), pCache := 0
        DllCall("ole32\CLSIDFromString", "Str", "{53660488-8855-460B-A9AB-5CFC6B5012CA}", "Ptr", sid)
        DllCall("ole32\CLSIDFromString", "Str", "{4214F6FA-EB36-4E2F-9CA2-23FDC1832DF7}", "Ptr", iid)
        ComCall(3, sp, "Ptr", sid, "Ptr", iid, "Ptr*", &pCache)
        if pCache {
            loop 48 {
                try ComCall(3, pCache, "Int", A_Index - 1)
            }
            ObjRelease(pCache)
        }
    }
}

DisableTouchpadGestures() {
    global savedGestures, savedTouchGesture, ptpKey, deskKey, gestureNames
    savedGestures := Map()
    try {
        loop reg ptpKey, "V" {
            if A_LoopRegType != "REG_DWORD"
                continue
            if A_LoopRegName ~= "i)Finger"
                savedGestures[A_LoopRegName] := { exists: true, value: Integer(RegRead(ptpKey, A_LoopRegName)) }
        }
    }
    for name in gestureNames {
        if !savedGestures.Has(name)
            savedGestures[name] := { exists: false, value: 0 }
        try RegWrite(0, "REG_DWORD", ptpKey, name)
    }
    savedTouchGesture := unset
    try savedTouchGesture := { exists: true, value: Integer(RegRead(deskKey, "TouchGestureSetting")) }
    catch
        savedTouchGesture := { exists: false, value: 0 }
    try RegWrite(0, "REG_DWORD", deskKey, "TouchGestureSetting")
    NotifyTouchpadSettings()
}

RestoreTouchpadGestures() {
    global savedGestures, savedTouchGesture, ptpKey, deskKey
    for name, info in savedGestures {
        if info.exists {
            try RegWrite(info.value, "REG_DWORD", ptpKey, name)
        } else {
            try RegDelete(ptpKey, name)
        }
    }
    savedGestures := Map()
    if IsSet(savedTouchGesture) {
        if savedTouchGesture.exists {
            try RegWrite(savedTouchGesture.value, "REG_DWORD", deskKey, "TouchGestureSetting")
        } else {
            try RegDelete(deskKey, "TouchGestureSetting")
        }
        savedTouchGesture := unset
    }
    NotifyTouchpadSettings()
}

Cleanup(*) {
    global locked
    if locked
        Unlock()
}

Unlock() {
    global locked, lockedHwnd
    SetTimer(KeepFocus, 0)
    RestoreTouchpadGestures()
    if lockedHwnd {
        try WinSetAlwaysOnTop(false, lockedHwnd)
    }
    locked := false
    lockedHwnd := 0
    TrayTip("NeoColab kiosk", "Unlocked")
}

KeepFocus() {
    global locked, lockedHwnd
    if !locked
        return
    if !WinExist(lockedHwnd) {
        Unlock()
        return
    }
    try {
        if WinExist("ahk_class MultitaskingViewFrame")
            Send("{Esc}")
        if WinExist("ahk_class XamlExplorerHostIslandWindow")
            Send("{Esc}")
        if WinExist("ahk_class Windows.UI.Core.CoreWindow") {
            t := WinGetTitle("ahk_class Windows.UI.Core.CoreWindow")
            if t ~= "i)Task View|Desktops|Snap"
                Send("{Esc}")
        }
    }
    if WinExist("A") != lockedHwnd {
        try WinActivate(lockedHwnd)
    }
}

ToggleLock(*) {
    global locked, lockedHwnd
    if locked {
        Unlock()
        return
    }
    hwnd := WinExist("A")
    if !IsTargetWindow(hwnd) {
        TrayTip("NeoColab kiosk", "Click the Neo Browser or Chrome window first, then Ctrl+Alt+L")
        return
    }
    lockedHwnd := hwnd
    locked := true
    DisableTouchpadGestures()
    try WinSetAlwaysOnTop(true, hwnd)
    try WinMaximize(hwnd)
    try WinActivate(hwnd)
    SetTimer(KeepFocus, 200)
    TrayTip("NeoColab kiosk", "Locked — Ctrl+Alt+L to unlock")
}

^!l:: ToggleLock()

#HotIf locked
LWin:: Return
RWin:: Return
!Tab:: Return
!+Tab:: Return
!Esc:: Return
^Esc:: Return
#Tab:: Return
#+Tab:: Return
#^Left:: Return
#^Right:: Return
#^Up:: Return
#^Down:: Return
#d:: Return
#HotIf
