; Pixel Predator v2.0 (rewrite)
; Requires AutoHotkey v1.1+ and Gdip.ahk (included below as a function set)
#SingleInstance Force
#NoEnv
ListLines Off
SetBatchLines -1
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
SetDefaultMouseSpeed 0

Gdip_Startup()

; ---------- Global state ----------
global Targets := []          ; each: {Color, Variation, X1,Y1,X2,Y2, Enabled}
global BetweenX := "", BetweenY := ""
global Running := false
global StartKey := "F1", StopKey := "F2"
global PickingArea := false, AreaTarget := 0, AreaStep := 0
global ax1, ay1, ax2, ay2
global ClickMode := "Click"   ; Click | Move
global ClickButton := "Left", ClickCount := 1, ClickHold := 30
global HoldDelay := 30, LoopDelay := 500, XOff := 10, YOff := 10
global LoopOn := true, BetweenOn := false, BetweenDelay := 100
global SendKeys := ""

Hotkey, %StartKey%, StartSearch
Hotkey, %StopKey%, StopSearch

; ---------- Colours ----------
; Lighter palette: slate greys with a soft lavender accent
global cBG := "2F3137", cPanel := "3A3D45", cField := "262930"
global cAccent := "A78BFA", cText := "E6E6EA", cMuted := "9A9DA8"

; ---------- Main GUI ----------
Gui, Main:New, +AlwaysOnTop -Caption +Border +LastFound +HwndMainHwnd, Pixel Search
Gui, Main:Color, %cBG%, %cPanel%
Gui, Main:Font, c%cText% s9, Segoe UI

; Title bar (drag area) - whole window is draggable via WM_LBUTTONDOWN handler
Gui, Main:Font, c%cAccent% s12 Bold
Gui, Main:Add, Text, x0 y0 w460 h36 BackgroundTrans gDragWindow vDragBar Center, Pixel Search
Gui, Main:Font, c%cText% s9 Norm

; Section: Colour targets
Gui, Main:Add, GroupBox, x10 y40 w440 h190 c%cMuted%, Colour targets
Gui, Main:Add, ListView, x20 y60 w420 h120 vTargetList Grid -Multi +Background%cField% c%cText%, On|Colour|Variation|Search area
LV_ModifyCol(1, 40), LV_ModifyCol(2, 90), LV_ModifyCol(3, 80), LV_ModifyCol(4, 190)
Gui, Main:Add, Button, x20 y188 w100 h26 gAddTarget, Add target
Gui, Main:Add, Button, x125 y188 w100 h26 gRemoveTarget, Remove
Gui, Main:Add, Button, x230 y188 w100 h26 gPickColour, Pick colour
Gui, Main:Add, Button, x335 y188 w100 h26 gPickArea, Set area

; Section: Between click
Gui, Main:Add, GroupBox, x10 y240 w440 h70 c%cMuted%, Between click (optional)
Gui, Main:Add, Checkbox, x20 y260 w200 h22 vBetweenOn gToggleBetween, Click a saved point after each find
Gui, Main:Add, Button, x230 y257 w100 h26 gPickBetween, Set point
Gui, Main:Add, Text, x340 y262 w100 h22 vBetweenLabel, not set

; Section: Click settings
Gui, Main:Add, GroupBox, x10 y320 w440 h150 c%cMuted%, Action
Gui, Main:Add, Radio, x20 y342 w110 h22 vRadioClick Checked gSetMode, Click
Gui, Main:Add, Radio, x140 y342 w110 h22 vRadioMove gSetMode, Move mouse only
Gui, Main:Add, Text, x20 y372 w120 h22, Mouse button
Gui, Main:Add, DropDownList, x140 y370 w100 vClickButton Choose1, Left|Middle|Right
Gui, Main:Add, Text, x260 y372 w110 h22, Clicks per find
Gui, Main:Add, Edit, x370 y370 w60 h22 Number vClickCount, 1
Gui, Main:Add, Text, x20 y402 w120 h22, X offset
Gui, Main:Add, Edit, x140 y400 w60 h22 Number vXOff, 10
Gui, Main:Add, Text, x220 y402 w120 h22, Y offset
Gui, Main:Add, Edit, x340 y400 w60 h22 Number vYOff, 10
Gui, Main:Add, Text, x20 y432 w120 h22, Hold time (ms)
Gui, Main:Add, Edit, x140 y430 w60 h22 Number vClickHold, 30
Gui, Main:Add, Text, x220 y432 w120 h22, Loop delay (ms)
Gui, Main:Add, Edit, x340 y430 w60 h22 Number vLoopDelay, 500

; Section: Loop + keys
Gui, Main:Add, GroupBox, x10 y478 w440 h80 c%cMuted%, Loop and keys
Gui, Main:Add, Checkbox, x20 y498 w200 h22 vLoopOn Checked, Keep searching (loop)
Gui, Main:Add, Text, x20 y526 w110 h22, Keys to send
Gui, Main:Add, Edit, x140 y524 w300 h22 vSendKeys,

; Footer
Gui, Main:Add, Text, x20 y566 w110 h22, Start: %StartKey%
Gui, Main:Add, Text, x140 y566 w110 h22, Stop: %StopKey%
Gui, Main:Add, Button, x250 y562 w90 h26 gStartBtn, Start
Gui, Main:Add, Button, x345 y562 w90 h26 gStopBtn, Stop
Gui, Main:Show, w460 h600, Pixel Search

return

; ---------- Window drag ----------
DragWindow:
    PostMessage, 0xA1, 2
return

GuiClose:
MainGuiClose:
    ExitApp

; ---------- Mode toggles ----------
SetMode:
    Gui, Main:Submit, NoHide
    ClickMode := RadioClick ? "Click" : "Move"
return

ToggleBetween:
    Gui, Main:Submit, NoHide
    BetweenOn := BetweenOn ? 1 : 0
return

; ---------- Colour targets ----------
AddTarget:
    Gui, Main:Submit, NoHide
    if (AreaX1 = "") {
        MsgBox, 48, Pixel Search, Set a search area first.
        return
    }
    Targets.Push({Color: SelectedColor, Variation: Variation, X1: AreaX1, Y1: AreaY1, X2: AreaX2, Y2: AreaY2, Enabled: 1})
    RefreshTargetList()
return

RemoveTarget:
    row := LV_GetNext(0)
    if (row) {
        Targets.RemoveAt(row)
        RefreshTargetList()
    }
return

RefreshTargetList() {
    LV_Delete()
    for i, t in Targets
        LV_Add("", t.Enabled ? "Yes" : "No", t.Color, t.Variation, t.X1 "," t.Y1 " to " t.X2 "," t.Y2)
}

PickColour:
    SetColourPicking(true)
return

PickArea:
    StartAreaPick()
return

PickBetween:
    StartBetweenPick()
return

; Generic hover-and-Ctrl picker (used by colour, area and between)
SetColourPicking(on) {
    global
    if (!on)
        return
    ToolTip, Hover over the colour and press Ctrl
    KeyWait, Ctrl, D
    MouseGetPos, px, py
    PixelGetColor, col, %px%, %py%, RGB
    SelectedColor := col
    ToolTip
    GuiControl, Main:, SelectedColor, %col%
}

; ---------- Area picking (two clicks, same as original) ----------
StartAreaPick() {
    global
    PickingArea := true, AreaStep := 1
    ToolTip, Click the top-left corner (Esc to cancel)
    SetTimer, AreaTick, 30
}

AreaTick:
    if (!PickingArea) {
        SetTimer, AreaTick, Off
        return
    }
    if (GetKeyState("Esc", "P")) {
        PickingArea := false, ToolTip
        return
    }
    if (AreaStep = 1 && GetKeyState("LButton", "P")) {
        MouseGetPos, ax1, ay1
        AreaStep := 2
        ToolTip, Click the bottom-right corner
        KeyWait, LButton
    } else if (AreaStep = 2 && GetKeyState("LButton", "P")) {
        MouseGetPos, ax2, ay2
        AreaX1 := ax1, AreaY1 := ay1, AreaX2 := ax2, AreaY2 := ay2
        GuiControl, Main:, AreaX1, %ax1%
        PickingArea := false, AreaStep := 0
        ToolTip
        SetTimer, AreaTick, Off
        KeyWait, LButton
    }
return

; ---------- Between point ----------
StartBetweenPick() {
    global
    ToolTip, Hover over the button and press Ctrl
    KeyWait, Ctrl, D
    MouseGetPos, BetweenX, BetweenY
    GuiControl, Main:, BetweenLabel, %BetweenX%, %BetweenY%
    ToolTip
}

; ---------- Start / stop ----------
StartBtn:
    StartSearch()
return

StopBtn:
    StopSearch()
return

StartSearch() {
    global
    if (Targets.Length() = 0) {
        MsgBox, 48, Pixel Search, Add at least one colour target.
        return
    }
    Gui, Main:Submit, NoHide
    Running := true
    while (Running) {
        found := false
        for i, t in Targets {
            if (!t.Enabled)
                continue
            PixelSearch, px, py, t.X1, t.Y1, t.X2, t.Y2, t.Color, t.Variation, Fast RGB
            if (!ErrorLevel) {
                found := true
                DoAction(px, py)
                if (BetweenOn && BetweenX != "")
                    ClickAt(BetweenX, BetweenY)
                break
            }
        }
        if (!found && SendKeys != "")
            Send, %SendKeys%
        if (!LoopOn) {
            Running := false
            break
        }
        Sleep, %LoopDelay%
    }
}

StopSearch() {
    global
    Running := false
}

DoAction(px, py) {
    global ClickMode, ClickCount, ClickButton, XOff, YOff, SendKeys
    if (ClickMode = "Click")
        ClickAt(px + XOff, py + YOff, ClickCount)
    else
        MouseMove, px + XOff, py + YOff, 0
    if (SendKeys != "")
        Send, %SendKeys%
}

ClickAt(x, y, count := 1) {
    global ClickButton, ClickHold
    MouseMove, x, y, 0
    Loop, %count% {
        Click, %ClickButton%, Down
        Sleep, %ClickHold%
        Click, %ClickButton%, Up
    }
}

; ---------- Hotkey passthroughs ----------
F1::StartSearch()
F2::StopSearch()

; ==========================================================
; Gdip helpers (trimmed to what this script needs)
; ==========================================================
Gdip_Startup() {
    if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
        DllCall("LoadLibrary", "str", "gdiplus")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", pToken, "UPtr", &si, "UPtr", 0)
    return pToken
}