; ==============================================================================
; Roblox Performance Helper V1 (AutoHotkey v2)
; Built from the ideas in the Milamoo12340 repos, rewritten so every change is
; reversible from one "Revert all" button. Nothing is changed until you press
; Apply (or the options are already ticked when the helper starts).
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp
}

global IniFile := A_ScriptDir "\RobloxHelper.ini"
global LogFile := A_ScriptDir "\RobloxHelper.log"
global RobloxExe := "RobloxPlayerBeta.exe"
global HighPerfGuid := "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
global OrigPlan := ""
global PowerApplied := false
global TimerApplied := false
global AntiIdleOn := false
global StoppedSvcs := []
global GpuSet := Map()
global Cores := 0, RamGB := 0
global Checks := Map()
global StatusText := ""
global G := ""

global Opt := Map("priority", 1, "power", 1, "timer", 1, "gpu", 1, "services", 0, "antiidle", 0)
global ServiceNames := ["SysMain", "WSearch"]

LoadSettings()
DetectHardware()
BuildGui()
OnExit(ExitCleanup)
Apply()
SetTimer(Maintain, 15000)
HLog("Helper started. " Cores " threads, " RamGB " GB RAM")

; ------------------------------------------------------------------ settings --
LoadSettings() {
    global Opt, IniFile
    for key, def in Opt.Clone() {
        v := IniRead(IniFile, "options", key, def)
        Opt[key] := Integer(v)
    }
}

SaveSettings() {
    global Opt, IniFile
    for key, val in Opt
        IniWrite(val, IniFile, "options", key)
}

SaveFromGui() {
    global Opt, Checks
    for key, ctl in Checks
        Opt[key] := ctl.Value ? 1 : 0
    SaveSettings()
}

; ---------------------------------------------------------------- hardware ----
DetectHardware() {
    global Cores, RamGB
    try {
        for cpu in ComObjGet("winmgmts:").ExecQuery("SELECT NumberOfLogicalProcessors FROM Win32_Processor")
            Cores := cpu.NumberOfLogicalProcessors
        for cs in ComObjGet("winmgmts:").ExecQuery("SELECT TotalPhysicalMemory FROM Win32_ComputerSystem")
            RamGB := Round(cs.TotalPhysicalMemory / 1073741824, 1)
    }
}

RobloxProcs() {
    global RobloxExe
    list := []
    try {
        for p in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, ExecutablePath FROM Win32_Process WHERE Name = '" RobloxExe "'")
            list.Push({pid: p.ProcessId, path: p.ExecutablePath})
    }
    return list
}

; ------------------------------------------------------------------- apply ----
Apply() {
    global Opt, PowerApplied, TimerApplied, AntiIdleOn, ServiceNames, StoppedSvcs
    if Opt["power"] && !PowerApplied {
        ApplyPower()
    }
    if Opt["timer"] && !TimerApplied {
        DllCall("winmm\timeBeginPeriod", "UInt", 1)
        TimerApplied := true
        HLog("Timer resolution set to 1 ms")
    }
    if Opt["services"] && StoppedSvcs.Length = 0 {
        for name in ServiceNames {
            RunWait("cmd /c sc stop " name, , "Hide")
            StoppedSvcs.Push(name)
            HLog("Stopped service: " name)
        }
    }
    if Opt["antiidle"] && !AntiIdleOn {
        AntiIdleOn := true
        SetTimer(AntiIdle, 540000)
        HLog("Anti-idle on: Space every 9 minutes while Roblox is the active window")
    }
    Maintain()
}

ApplyPower() {
    global OrigPlan, PowerApplied, HighPerfGuid
    OrigPlan := ActivePlan()
    RunWait("cmd /c powercfg /setactive " HighPerfGuid, , "Hide")
    PowerApplied := true
    HLog("Power plan: switched to High performance (was " OrigPlan ")")
}

ActivePlan() {
    out := ReadCmd("powercfg /getactivescheme")
    if RegExMatch(out, "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", &m)
        return m[0]
    return ""
}

ReadCmd(cmd) {
    try {
        exec := ComObject("WScript.Shell").Exec(A_ComSpec " /c " cmd)
        return exec.StdOut.ReadAll()
    }
    return ""
}

; Runs every 15 s: Roblox restarts often, so new processes need the same treatment.
Maintain() {
    global Opt, GpuSet, StatusText
    procs := RobloxProcs()
    for p in procs {
        if Opt["priority"]
            try ProcessSetPriority("High", p.pid)
        if Opt["gpu"] && p.path != "" && !GpuSet.Has(p.path) {
            try {
                RegWrite("GpuPreference=2;", "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\DirectX\UserGpuPreferences", p.path)
                GpuSet[p.path] := true
                HLog("GPU preference set to high performance for " p.path)
            }
        }
    }
    if IsObject(StatusText)
        StatusText.Value := procs.Length " Roblox process(es) running. Options on: " OptionSummary()
}

OptionSummary() {
    global Opt
    s := ""
    for key, val in Opt
        if val
            s .= key " "
    return s = "" ? "none" : Trim(s)
}

AntiIdle(*) {
    if WinActive("ahk_exe " RobloxExe)
        Send("{Space}")
}

; ------------------------------------------------------------------- revert ---
Revert() {
    global OrigPlan, PowerApplied, TimerApplied, AntiIdleOn, StoppedSvcs, GpuSet, HighPerfGuid
    if PowerApplied && OrigPlan != "" {
        RunWait("cmd /c powercfg /setactive " OrigPlan, , "Hide")
        HLog("Power plan restored to " OrigPlan)
    }
    PowerApplied := false
    if TimerApplied {
        DllCall("winmm\timeEndPeriod", "UInt", 1)
        TimerApplied := false
        HLog("Timer resolution restored")
    }
    for name in StoppedSvcs {
        RunWait("cmd /c sc config " name " start= auto", , "Hide")
        RunWait("cmd /c sc start " name, , "Hide")
        HLog("Restarted service: " name)
    }
    StoppedSvcs := []
    for path, _ in GpuSet {
        try RegDelete("HKEY_CURRENT_USER\Software\Microsoft\DirectX\UserGpuPreferences", path)
    }
    GpuSet := Map()
    if AntiIdleOn {
        SetTimer(AntiIdle, 0)
        AntiIdleOn := false
    }
    HLog("Everything reverted")
    if IsObject(StatusText)
        StatusText.Value := "Reverted. Press Apply to turn options back on."
}

ExitCleanup(*) {
    global TimerApplied
    if TimerApplied
        DllCall("winmm\timeEndPeriod", "UInt", 1)
}

; ---------------------------------------------------------------------- GUI ---
BuildGui() {
    global G, Checks, StatusText, Cores, RamGB, Opt
    G := Gui("+AlwaysOnTop", "Roblox Performance Helper")
    G.SetFont("s9", "Segoe UI")
    G.Add("Text", "w380", "This PC: " Cores " threads, " RamGB " GB RAM")
    items := [
        ["priority", "Roblox to High CPU priority (rechecked every 15 s)"],
        ["power", "High performance power plan (uses more power on laptops)"],
        ["timer", "1 ms timer resolution (smoother frame and input timing)"],
        ["gpu", "Roblox GPU preference: high performance"],
        ["services", "Pause SysMain and Windows Search while the helper runs"],
        ["antiidle", "Anti-idle: press Space every 9 min while Roblox is active"]
    ]
    for item in items {
        key := item[1]
        opts := Opt[key] ? "Checked" : ""
        Checks[key] := G.Add("CheckBox", opts, item[2])
    }
    G.Add("Button", "w180 Default", "Apply now").OnEvent("Click", (*) => (SaveFromGui(), Apply()))
    G.Add("Button", "x+10 w180", "Revert all").OnEvent("Click", (*) => Revert())
    G.Add("Button", "xm w180", "Create restore point").OnEvent("Click", (*) => RestorePoint())
    StatusText := G.Add("Text", "xm w380 h40", "Starting...")
    G.OnEvent("Close", (*) => G.Hide())
    G.Show("w410")
}

RestorePoint() {
    RunWait("powershell -NoProfile -Command " "Checkpoint-Computer -Description 'Roblox Helper' -RestorePointType MODIFY_SETTINGS" "", , "Hide")
    HLog("Restore point requested")
}

HLog(msg) {
    global LogFile
    FileAppend(FormatTime(A_Now, "HH:mm:ss") "  " msg "`n", LogFile)
}
