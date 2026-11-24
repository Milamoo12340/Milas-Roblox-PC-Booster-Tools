; ==============================================================================
;   🐺PS99  OPTIMIZER🐺   -  Command Center
;  AutoHotkey v2.  Runs as administrator (it will ask once).
;
;  Pages:  Dashboard | Boost | Cleaner | Processes | Roblox | Tools | Scripts | Settings
;
;  Design rules
;   - Every system change is tracked and undone by "REVERT ALL" (registry values
;     are backed up to the INI, so a revert even works after a reboot).
;   - Nothing touches Roblox's memory or handles. Multi-instance works by claiming
;     the singleton mutex BEFORE Roblox starts, not by reaching into its process.
;   - No placebo tweaks. Each option says what it really does.
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off
Persistent()
SetWorkingDir(A_ScriptDir)

if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    }
    ExitApp	
}

; ------------------------------------------------------------------ GLOBALS ---
global APP_NAME := "PS99 ⢏⢢⣀⡔⡹ Optimizer"
global APP_VER := " "
global IniFile := A_ScriptDir "\PS99Optimizer.ini"
global LogFile := A_ScriptDir "\PS99Optimizer.log"
global ScriptsDir := A_ScriptDir "\Scripts"
global RobloxExe := "RobloxPlayerBeta.exe"
global GUID_HIGH := "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
global GUID_ULT := "e9a42b02-d5df-448d-aa00-03f14749eb61"
global CX := 205, CW := 670, HIST := 32

; Toggles (0/1). Saved in the INI under [options].
global Opt := Map(
    "priority", 1, "focusprio", 0, "power", 1, "ultimate", 0, "cool", 0, "timer", 1,
    "gpu", 1, "gamemode", 1, "dvr", 1, "fso", 0, "services", 0, "antiidle", 0,
    "throttle", 0, "autoboost", 1, "autorevert", 1, "revertonexit", 1, "closetray", 1,
    "startwin", 0, "multi", 0, "autotrim", 0, "autostandby", 0, "clicker", 0, "clickroblox", 1,
    "flags", 0, "ffps", 1, "fpost", 0, "fquality", 0, "fgrass", 0, "ftex", 0, "fd3d11", 0
)
; Values. Saved in the INI under [config].
global Cfg := Map(
    "theme", "Neon", "closer", "", "closermode", "Throttle", "trimpct", "85", "idlemin", "9",
    "placeid", "8737899170", "mutexnames", "ROBLOX_singletonMutex",
    "services", "SysMain|WSearch|DiagTrack", "fpscap", "240", "cps", "10", "extra", ""
)

global S := {
    page: "Dashboard", boosted: false, boostTick: 0,
    origPlan: "", dupPlan: "", powerApplied: false, coolApplied: false, coolPlan: "",
    timerApplied: false, stoppedSvcs: [], throttled: Map(), tweaked: Map(),
    mutexes: [], antiIdleOn: false, prevHz: 0, hzChanged: false,
    robloxWas: false, rbxStart: 0, rbxCount: 0, rbxMB: 0, peakRbxMB: 0,
    startTick: A_TickCount, freedMB: 0, lastTrim: 0, cleanBusy: false,
    cores: 1, totalRamGB: 0, cpuName: "Unknown CPU", gpuName: "Unknown GPU", osName: "Windows",
    cpuHist: [], ramHist: [], gpuHist: [], gpuLoad: -1, gpuTick: 0,
    lastHover: 0, scripts: Map(), clicking: false, wmi: ""
}

global G := ""
global T := ""
global C := Map()
global Pages := Map()
global NavBtns := Map()
global Checks := Map()
global HoverMap := Map()
global NavNames := ["Dashboard", "Boost", "Cleaner", "Processes", "Roblox", "Tools", "Scripts", "Settings"]
global NavIcons := Map("Dashboard", "🌸", "Boost", "✨", "Cleaner", "🔎", "Processes", "🗁",
    "Roblox", "🐾", "Tools", "🛠️", "Scripts", "✎_", "Settings", "⚙️")

global Themes := Map(
    "Neon", MakeTheme("0B0D12", "10131A", "171B25", "212736", "00E5FF", "FF3DA5"),
    "Sunset", MakeTheme("120C10", "190F15", "241520", "301B2A", "FF8A3D", "FF3D81"),
    "Ocean", MakeTheme("08101C", "0C1626", "122036", "1A2D4A", "4DA3FF", "7C5CFF"),
    "Matrix", MakeTheme("070B08", "0B120C", "101A12", "17251A", "39FF14", "00C853"),
    "Violet", MakeTheme("0E0B14", "140F1D", "1C1529", "271D3A", "B66DFF", "FF5CC8")
)
 
MakeTheme(bg, side, panel, panel2, accent, accent2) {
    return Map("bg", bg, "side", side, "panel", panel, "panel2", panel2, "accent", accent,
        "accent2", accent2, "text", "E9EEF7", "dim", "8892A6", "onAccent", "06080C",
        "good", "3DFF9A", "warn", "FFC53D", "bad", "FF4D5E")
}

; ============================================================ SMALL HELPERS ===
LogMsg(msg) {
    line := FormatTime(A_Now, "HH:mm:ss") "  " msg
    try FileAppend(line "`n", LogFile, "UTF-8")
    if C.Has("log") {
        try {
            box := C["log"]
            cur := box.Value
            if (StrLen(cur) > 14000)
                cur := SubStr(cur, -7000)
            box.Value := cur line "`r`n"
            SendMessage(0x115, 7, 0, box)
        }
    }
}

Notify(msg) {
    try TrayTip(msg, APP_NAME)
}

SetText(ctl, txt) {
    try {
        if (ctl.Value != txt)
            ctl.Value := txt
    }
}

JoinArr(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") v
    return out
}

HasItem(arr, val) {
    for v in arr {
        if (v = val)
            return true
    }
    return false
}

FmtDur(ms) {
    sec := ms // 1000
    return Format("{:02}:{:02}:{:02}", sec // 3600, Mod(sec // 60, 60), Mod(sec, 60))
}

FmtMB(bytes) {
    return Round(bytes / 1048576, 1) " MB"
}

Lighten(hex, amt := 28) {
    rr := Min(255, Integer("0x" SubStr(hex, 1, 2)) + amt)
    gg := Min(255, Integer("0x" SubStr(hex, 3, 2)) + amt)
    bb := Min(255, Integer("0x" SubStr(hex, 5, 2)) + amt)
    return Format("{:02X}{:02X}{:02X}", rr, gg, bb)
}

Spark(arr) {
    static blocks := ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    out := ""
    for v in arr
        out .= blocks[Max(1, Min(8, Ceil(v / 12.5)))]
    return out
}

PushHist(arr, v) {
    arr.Push(v)
    if (arr.Length > HIST)
        arr.RemoveAt(1)
}

ReadCmd(cmd) {
    tmp := A_Temp "\ps99opt_" A_TickCount ".txt"
    out := ""
    try {
        RunWait(A_ComSpec ' /c ' cmd ' > "' tmp '" 2>&1', , "Hide")
        out := FileRead(tmp)
        FileDelete(tmp)
    }
    return out
}

ParseNames(str) {
    out := []
    for n in StrSplit(str, [",", ";", "|", "`n"], " `t`r") {
        n := StrLower(n)
        if (n = "" || !RegExMatch(n, "^[\w\.\-]+$"))
            continue
        if !InStr(n, ".")
            n .= ".exe"
        out.Push(n)
    }
    return out
}

ParseMutexNames(str) {
    out := []
    for n in StrSplit(str, [",", ";", "|"], " `t`r`n") {
        if (n != "" && RegExMatch(n, "^[\w\.\-]+$"))
            out.Push(n)
    }
    return out
}

IsProtected(nm) {
    static prot := "|system|idle|registry|smss|csrss|wininit|services|lsass|winlogon|svchost|dwm|explorer"
        . "|fontdrvhost|lsm|memory compression|securityhealthservice|msmpeng|nissrv|sihost|taskhostw"
        . "|ctfmon|searchhost|startmenuexperiencehost|shellexperiencehost|audiodg|spoolsv|wudfhost"
        . "|dllhost|conhost|runtimebroker|robloxplayerbeta|robloxcrashhandler|autohotkey64|autohotkey32"
        . "|autohotkeyu64|autohotkey|"
    nm := StrLower(RegExReplace(nm, "\.exe$"))
    return InStr(prot, "|" nm "|") ? true : false
}

; ============================================================== SETTINGS =====
LoadSettings() {
    for k, d in Opt.Clone() {
        try Opt[k] := Integer(IniRead(IniFile, "options", k, d))
    }
    for k, d in Cfg.Clone()
        Cfg[k] := IniRead(IniFile, "config", k, d)
    if !Themes.Has(Cfg["theme"])
        Cfg["theme"] := "Neon"
}

SaveSettings() {
    for k, v in Opt
        IniWrite(v, IniFile, "options", k)
    for k, v in Cfg
        IniWrite(v, IniFile, "config", k)
}

OptToggled(key, ctl, *) {
    Opt[key] := ctl.Value ? 1 : 0
    SaveSettings()
    if (key = "multi") {
        if Opt["multi"]
            EnableMulti()
        else
            DisableMulti()
    } else if (key = "clicker") {
        if Opt["clicker"] {
            Hotkey("F8", "On")
        } else {
            Hotkey("F8", "Off")
            if S.clicking
                ToggleClickerForce(false)
        }
        UpdateClickStatus()
    } else if (key = "startwin") {
        SetStartWithWindows(Opt["startwin"])
    } else if (key = "antiidle") {
        if (!Opt["antiidle"] && S.antiIdleOn)
            StopAntiIdle()
        else if (Opt["antiidle"] && S.boosted)
            StartAntiIdle()
    }
}

CfgChanged(key, ctl, *) {
    Cfg[key] := ctl.Value
    SaveSettings()
}

; ============================================================== HARDWARE =====
DetectHardware() {
    try {
        for cp in S.wmi.ExecQuery("SELECT Name, NumberOfLogicalProcessors FROM Win32_Processor") {
            S.cpuName := Trim(cp.Name)
            S.cores := Max(1, Integer(cp.NumberOfLogicalProcessors))
            break
        }
    }
    names := []
    try {
        for vc in S.wmi.ExecQuery("SELECT Name FROM Win32_VideoController") {
            names.Push(Trim(vc.Name))
        }
    }
    if names.Length
        S.gpuName := JoinArr(names, "  /  ")
    try {
        for os in S.wmi.ExecQuery("SELECT Caption FROM Win32_OperatingSystem") {
            S.osName := Trim(os.Caption)
            break
        }
    }
    S.totalRamGB := Round(MemInfo().totalMB / 1024, 1)
}

CpuLoad() {
    static pIdle := 0, pKernel := 0, pUser := 0
    idle := 0, kernel := 0, user := 0
    DllCall("GetSystemTimes", "Int64*", &idle, "Int64*", &kernel, "Int64*", &user)
    dI := idle - pIdle, dK := kernel - pKernel, dU := user - pUser
    pIdle := idle, pKernel := kernel, pUser := user
    tot := dK + dU
    return tot > 0 ? Round((tot - dI) * 100 / tot) : 0
}

MemInfo() {
    ms := Buffer(64, 0)
    NumPut("UInt", 64, ms, 0)
    DllCall("GlobalMemoryStatusEx", "Ptr", ms)
    total := NumGet(ms, 8, "UInt64") / 1048576
    avail := NumGet(ms, 16, "UInt64") / 1048576
    return {load: NumGet(ms, 4, "UInt"), totalMB: total, availMB: avail, usedMB: total - avail}
}

GpuLoad() {
    try {
        sum := 0
        for en in S.wmi.ExecQuery("SELECT Name, UtilizationPercentage FROM Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine WHERE Name LIKE '%engtype_3D%'")
            sum += en.UtilizationPercentage
        return Min(100, Round(sum))
    }
    return -1
}

RobloxProcs() {
    list := []
    try {
        for pr in S.wmi.ExecQuery("SELECT ProcessId, ExecutablePath, WorkingSetSize FROM Win32_Process WHERE Name = '" RobloxExe "'") {
            pth := "", wss := 0
            try pth := pr.ExecutablePath
            try wss := Number(pr.WorkingSetSize)
            list.Push({pid: Integer(pr.ProcessId), path: pth, ws: wss})
        }
    }
    return list
}

; ============================================== REVERSIBLE REGISTRY HELPERS ===
RegTrack(key, name, value, type := "REG_DWORD") {
    id := key "|" name
    existing := IniRead(IniFile, "regbackup", id, "<unset>")
    if (existing = "<unset>") {
        old := "<none>"
        try old := RegRead(key, name)
        IniWrite(type "|" old, IniFile, "regbackup", id)
    }
    try {
        RegWrite(value, type, key, name)
        return true
    } catch as e {
        LogMsg("Registry write failed (" name "): " e.Message)
        return false
    }
}

RegRevertAll() {
    data := ""
    try data := IniRead(IniFile, "regbackup")
    if (data = "")
        return
    for line in StrSplit(data, "`n", "`r") {
        eq := InStr(line, "=")
        if !eq
            continue
        id := SubStr(line, 1, eq - 1)
        val := SubStr(line, eq + 1)
        bar1 := InStr(id, "|")
        bar2 := InStr(val, "|")
        if (!bar1 || !bar2)
            continue
        key := SubStr(id, 1, bar1 - 1)
        nm := SubStr(id, bar1 + 1)
        type := SubStr(val, 1, bar2 - 1)
        old := SubStr(val, bar2 + 1)
        try {
            if (old = "<none>")
                RegDelete(key, nm)
            else
                RegWrite(old, type, key, nm)
        }
        try IniDelete(IniFile, "regbackup", id)
    }
}

; ================================================================ BOOST ======
Apply(*) {
    LogMsg("Applying boost...")
    if Opt["power"]
        ApplyPower()
    if Opt["cool"]
        ApplyCool()
    if Opt["timer"]
        ApplyTimer()
    if Opt["gamemode"] {
        RegTrack("HKCU\Software\Microsoft\GameBar", "AutoGameModeEnabled", 1)
        RegTrack("HKCU\Software\Microsoft\GameBar", "AllowAutoGameMode", 1)
        LogMsg("Windows Game Mode: on")
    }
    if Opt["dvr"] {
        RegTrack("HKCU\System\GameConfigStore", "GameDVR_Enabled", 0)
        RegTrack("HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR", "AppCaptureEnabled", 0)
        LogMsg("Game DVR background capture: off")
    }
    if Opt["services"]
        PauseServices()
    if Opt["antiidle"]
        StartAntiIdle()
    if Opt["throttle"]
        ApplyTame()
    if Opt["flags"]
        ApplyFlags(true)
    S.boosted := true
    S.boostTick := A_TickCount
    TweakRoblox(RobloxProcs())
    LogMsg("Boost active.")
    UpdateStats()
}

BoostNow(*) {
    Apply()
    CleanRam(false)
    Notify("Boost applied")
}

TweakRoblox(procs) {
    fg := 0
    try fg := WinGetPID("A")
    fgIsRoblox := false
    for pr in procs {
        if (pr.pid = fg)
            fgIsRoblox := true
    }
    for pr in procs {
        if Opt["focusprio"] {
            if fgIsRoblox {
                try ProcessSetPriority((pr.pid = fg) ? "High" : "BelowNormal", pr.pid)
            }
        } else if Opt["priority"] {
            try ProcessSetPriority("High", pr.pid)
        }
        if (pr.path = "")
            continue
        if (Opt["gpu"] && !S.tweaked.Has(pr.path "|gpu")) {
            RegTrack("HKCU\Software\Microsoft\DirectX\UserGpuPreferences", pr.path, "GpuPreference=2;", "REG_SZ")
            S.tweaked[pr.path "|gpu"] := 1
            LogMsg("GPU preference set to high performance for Roblox")
        }
        if (Opt["fso"] && !S.tweaked.Has(pr.path "|fso")) {
            RegTrack("HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers", pr.path, "~ DISABLEDXMAXIMIZEDWINDOWEDMODE", "REG_SZ")
            S.tweaked[pr.path "|fso"] := 1
            LogMsg("Fullscreen optimizations disabled for Roblox (restart Roblox to take effect)")
        }
    }
}

SetPlan(guid) {
    return RunWait("powercfg /setactive " guid, , "Hide") = 0
}

ActivePlan() {
    out := ReadCmd("powercfg /getactivescheme")
    if RegExMatch(out, "i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", &m)
        return m[0]
    return ""
}

ApplyPower() {
    if S.powerApplied
        return
    S.origPlan := ActivePlan()
    src := Opt["ultimate"] ? GUID_ULT : GUID_HIGH
    if (src = GUID_HIGH && SetPlan(GUID_HIGH)) {
        S.powerApplied := true
        LogMsg("Power plan: High performance")
        return
    }
    out := ReadCmd("powercfg /duplicatescheme " src)
    if (RegExMatch(out, "i)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", &m) && SetPlan(m[1])) {
        S.dupPlan := m[1]
        S.powerApplied := true
        LogMsg("Power plan: " (Opt["ultimate"] ? "Ultimate Performance" : "High performance") " (temporary copy)")
    } else {
        LogMsg("Could not switch power plan on this PC")
    }
}

RevertPower() {
    if (S.origPlan != "")
        SetPlan(S.origPlan)
    if (S.dupPlan != "") {
        RunWait("powercfg /delete " S.dupPlan, , "Hide")
        S.dupPlan := ""
    }
    S.powerApplied := false
    LogMsg("Power plan restored")
}

ApplyCool() {
    if S.coolApplied
        return
    plan := ActivePlan()
    if (plan = "")
        return
    RunWait("powercfg /setacvalueindex " plan " SUB_PROCESSOR PROCTHROTTLEMAX 99", , "Hide")
    RunWait("powercfg /setactive " plan, , "Hide")
    S.coolPlan := plan
    S.coolApplied := true
    LogMsg("Cool mode: CPU capped at 99% (turbo boost off while plugged in)")
}

RevertCool() {
    if (S.coolPlan != "") {
        RunWait("powercfg /setacvalueindex " S.coolPlan " SUB_PROCESSOR PROCTHROTTLEMAX 100", , "Hide")
        if (ActivePlan() = S.coolPlan)
            RunWait("powercfg /setactive " S.coolPlan, , "Hide")
    }
    S.coolApplied := false
    LogMsg("Cool mode off (CPU cap back to 100%)")
}

ApplyTimer() {
    if S.timerApplied
        return
    cur := 0
    r := DllCall("ntdll\NtSetTimerResolution", "UInt", 5000, "Int", 1, "UInt*", &cur, "UInt")
    if (r = 0) {
        S.timerApplied := true
        LogMsg("Timer resolution requested: now " Round(cur / 10000, 2) " ms (newer Windows may scope this per process)")
    } else {
        LogMsg("Timer resolution request failed")
    }
}

RevertTimer() {
    if !S.timerApplied
        return
    cur := 0
    DllCall("ntdll\NtSetTimerResolution", "UInt", 5000, "Int", 0, "UInt*", &cur, "UInt")
    S.timerApplied := false
    LogMsg("Timer resolution released")
}

ServiceRunning(name) {
    return InStr(ReadCmd("sc query " name), "RUNNING") ? true : false
}

PauseServices() {
    if S.stoppedSvcs.Length
        return
    for nm in StrSplit(Cfg["services"], "|", " `t") {
        if (nm = "" || !RegExMatch(nm, "^[\w\.\-]+$"))
            continue
        if ServiceRunning(nm) {
            RunWait("sc stop " nm, , "Hide")
            S.stoppedSvcs.Push(nm)
            LogMsg("Paused service: " nm)
        }
    }
}

ResumeServices() {
    for nm in S.stoppedSvcs {
        RunWait("sc start " nm, , "Hide")
        LogMsg("Resumed service: " nm)
    }
    S.stoppedSvcs := []
}

StartAntiIdle() {
    if S.antiIdleOn
        return
    mins := 9
    try mins := Max(1, Integer(Cfg["idlemin"]))
    SetTimer(AntiIdle, mins * 60000)
    S.antiIdleOn := true
    LogMsg("Anti-idle on: Space every " mins " min while Roblox is the active window")
}

StopAntiIdle() {
    SetTimer(AntiIdle, 0)
    S.antiIdleOn := false
    LogMsg("Anti-idle off")
}

AntiIdle() {
    if WinActive("ahk_exe " RobloxExe)
        Send("{Space}")
}

; "Tame" = lower priority + Windows Efficiency mode for listed apps (default),
; or ask them to close politely (taskkill without /F).
ApplyTame() {
    names := ParseNames(Cfg["closer"])
    if !names.Length {
        LogMsg("Tame list is empty - add apps on the Boost page or from the Processes page")
        return
    }
    if (Cfg["closermode"] = "Close") {
        for nm in names {
            RunWait("taskkill /IM " nm, , "Hide")
            LogMsg("Asked " nm " to close")
        }
        return
    }
    count := 0
    me := ProcessExist()
    try {
        for pr in S.wmi.ExecQuery("SELECT ProcessId, Name FROM Win32_Process") {
            pid := Integer(pr.ProcessId)
            nm := StrLower(pr.Name)
            if (pid = me || IsProtected(nm) || S.throttled.Has(pid))
                continue
            if HasItem(names, nm) {
                try ProcessSetPriority("Low", pid)
                SetEco(pid, 1)
                S.throttled[pid] := true
                count++
            }
        }
    }
    LogMsg("Tamed " count " background process(es) (low priority + efficiency mode)")
}

RestoreTamed() {
    for pid, _ in S.throttled {
        if ProcessExist(pid) {
            try ProcessSetPriority("Normal", pid)
            SetEco(pid, 0)
        }
    }
    S.throttled := Map()
}

; state 1 = Efficiency mode (EcoQoS) on, 0 = back to system managed
SetEco(pid, state) {
    h := DllCall("OpenProcess", "UInt", 0x0200, "Int", 0, "UInt", pid, "Ptr")
    if !h
        return false
    st := Buffer(12, 0)
    NumPut("UInt", 1, st, 0)
    NumPut("UInt", state ? 1 : 0, st, 4)
    NumPut("UInt", state ? 1 : 0, st, 8)
    ok := DllCall("SetProcessInformation", "Ptr", h, "Int", 4, "Ptr", st, "UInt", 12)
    DllCall("CloseHandle", "Ptr", h)
    return ok
}

Revert(*) {
    LogMsg("Reverting everything...")
    if S.antiIdleOn
        StopAntiIdle()
    RestoreTamed()
    ResumeServices()
    if S.coolApplied
        RevertCool()
    if S.powerApplied
        RevertPower()
    RevertTimer()
    RegRevertAll()
    S.tweaked := Map()
    if S.hzChanged {
        SetRefresh(S.prevHz, false)
        S.hzChanged := false
    }
    S.boosted := false
    LogMsg("Everything reverted.")
    UpdateStats()
}

RestorePoint(*) {
    LogMsg("Creating a restore point (can take a moment)...")
    Sleep(50)
    rc := RunWait('powershell -NoProfile -Command "Checkpoint-Computer -Description PS99Optimizer -RestorePointType MODIFY_SETTINGS"', , "Hide")
    LogMsg(rc = 0 ? "Restore point requested (Windows allows one automatic point per 24 h)." : "Restore point failed - turn on System Protection for C: first.")
}

ApplyPreset(name, *) {
    static presets := Map(
        "Balanced", Map("priority", 1, "focusprio", 0, "power", 0, "ultimate", 0, "cool", 0, "timer", 1,
            "gpu", 1, "gamemode", 1, "dvr", 1, "fso", 0, "services", 0, "antiidle", 0, "throttle", 0),
        "Max FPS", Map("priority", 1, "focusprio", 0, "power", 1, "ultimate", 0, "cool", 0, "timer", 1,
            "gpu", 1, "gamemode", 1, "dvr", 1, "fso", 1, "services", 1, "antiidle", 0, "throttle", 1),
        "Cool and Quiet", Map("priority", 0, "focusprio", 0, "power", 0, "ultimate", 0, "cool", 1, "timer", 0,
            "gpu", 1, "gamemode", 1, "dvr", 1, "fso", 0, "services", 1, "antiidle", 0, "throttle", 1),
        "Multi-box", Map("priority", 0, "focusprio", 1, "power", 1, "ultimate", 0, "cool", 0, "timer", 1,
            "gpu", 1, "gamemode", 1, "dvr", 1, "fso", 0, "services", 1, "antiidle", 1, "throttle", 1)
    )
    for k, v in presets[name] {
        Opt[k] := v
        if Checks.Has(k)
            Checks[k].Value := v
    }
    SaveSettings()
    LogMsg("Preset '" name "' loaded - press APPLY BOOST to use it")
}

ModeChanged(ctl, *) {
    Cfg["closermode"] := ctl.Text
    SaveSettings()
    if (ctl.Text = "Close")
        MsgBox("'Close' asks the listed apps to close (like clicking X). Unsaved work in them can be lost.`n`n'Throttle' is the safer default: it keeps them open but drops their priority and puts them in Efficiency mode.", APP_NAME, "Icon!")
}

; ================================================================ CLEANER ====
CleanRam(includeStandby := false) {
    if S.cleanBusy
        return
    S.cleanBusy := true
    before := MemInfo().availMB
    n := TrimBackground()
    if includeStandby
        PurgeStandby()
    Sleep(300)
    gain := Max(0, MemInfo().availMB - before)
    S.freedMB += gain
    msg := "Trimmed " n " background processes" (includeStandby ? " + purged standby list" : "") " : +" Round(gain) " MB free"
    SetResult(msg)
    LogMsg(msg)
    S.cleanBusy := false
}

TrimBackground() {
    count := 0
    me := ProcessExist()
    try {
        for pr in S.wmi.ExecQuery("SELECT ProcessId, Name FROM Win32_Process") {
            pid := Integer(pr.ProcessId)
            if (pid = me || pid < 8 || IsProtected(pr.Name))
                continue
            if TrimPid(pid)
                count++
        }
    }
    return count
}

TrimPid(pid) {
    h := DllCall("OpenProcess", "UInt", 0x0500, "Int", 0, "UInt", pid, "Ptr")
    if !h
        return false
    ok := DllCall("psapi\EmptyWorkingSet", "Ptr", h)
    DllCall("CloseHandle", "Ptr", h)
    return ok
}

EnablePrivilege(name) {
    hTok := 0
    if !DllCall("advapi32\OpenProcessToken", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0x28, "Ptr*", &hTok)
        return false
    luid := Buffer(8, 0)
    if !DllCall("advapi32\LookupPrivilegeValueW", "Ptr", 0, "Str", name, "Ptr", luid) {
        DllCall("CloseHandle", "Ptr", hTok)
        return false
    }
    tp := Buffer(16, 0)
    NumPut("UInt", 1, tp, 0)
    NumPut("Int64", NumGet(luid, 0, "Int64"), tp, 4)
    NumPut("UInt", 2, tp, 12)
    ok := DllCall("advapi32\AdjustTokenPrivileges", "Ptr", hTok, "Int", 0, "Ptr", tp, "UInt", 0, "Ptr", 0, "Ptr", 0)
    err := A_LastError
    DllCall("CloseHandle", "Ptr", hTok)
    return ok && (err = 0)
}

PurgeStandby() {
    if !EnablePrivilege("SeProfileSingleProcessPrivilege") {
        LogMsg("Standby purge: could not get the required privilege")
        return false
    }
    cmd := 4
    st := DllCall("ntdll\NtSetSystemInformation", "Int", 80, "Int*", &cmd, "UInt", 4, "UInt")
    if (st != 0)
        LogMsg("Standby purge returned status 0x" Format("{:X}", st))
    return st = 0
}

CleanDir(dir, ageDays := 1) {
    freed := 0
    if !DirExist(dir)
        return 0
    cutoff := DateAdd(A_Now, -ageDays, "Days")
    Loop Files, dir "\*", "FR" {
        try {
            if (A_LoopFileTimeModified > cutoff)
                continue
            sz := A_LoopFileSize
            FileDelete(A_LoopFilePath)
            freed += sz
        }
    }
    Loop Files, dir "\*", "DR" {
        try DirDelete(A_LoopFilePath)
    }
    return freed
}

CleanTemp(*) {
    if MsgBox("Delete temp files older than 1 day from your Temp folder and C:\Windows\Temp?`nFiles in use are skipped.", APP_NAME, "YesNo Icon?") != "Yes"
        return
    freed := CleanDir(A_Temp) + CleanDir(A_WinDir "\Temp")
    msg := "Temp cleanup removed " FmtMB(freed)
    SetResult(msg)
    LogMsg(msg)
}

CleanRobloxLogs(*) {
    freed := CleanDir(EnvGet("LocalAppData") "\Roblox\logs", 1)
    msg := "Roblox logs cleanup removed " FmtMB(freed)
    SetResult(msg)
    LogMsg(msg)
}

FlushDns(*) {
    RunWait("ipconfig /flushdns", , "Hide")
    SetResult("DNS cache flushed")
    LogMsg("DNS cache flushed")
}

SetResult(txt) {
    if C.Has("cleanResult")
        SetText(C["cleanResult"], txt)
}

; ============================================================== PROCESSES ====
RefreshProcs(*) {
    lv := C["lvProc"]
    lv.Opt("-Redraw")
    lv.Delete()
    try {
        for pr in S.wmi.ExecQuery("SELECT Name, IDProcess, PercentProcessorTime, WorkingSetPrivate FROM Win32_PerfFormattedData_PerfProc_Process") {
            nm := pr.Name
            if (nm = "_Total" || nm = "Idle")
                continue
            cpuPct := Round(Number(pr.PercentProcessorTime) / Max(1, S.cores))
            ramMB := Round(Number(pr.WorkingSetPrivate) / 1048576)
            lv.Add(, RegExReplace(nm, "#\d+$"), Integer(pr.IDProcess), cpuPct, ramMB)
        }
    } catch as e {
        LogMsg("Process list failed: " e.Message)
    }
    lv.ModifyCol(1, 230)
    lv.ModifyCol(2, "Integer 90")
    lv.ModifyCol(3, "Integer 90")
    lv.ModifyCol(4, "Integer SortDesc 110")
    lv.Opt("+Redraw")
}

SelectedProcs() {
    lv := C["lvProc"]
    list := []
    row := 0
    while (row := lv.GetNext(row))
        list.Push({name: lv.GetText(row, 1), pid: Integer(lv.GetText(row, 2))})
    return list
}

EndSelected(*) {
    sel := SelectedProcs()
    if !sel.Length {
        LogMsg("Select one or more processes first")
        return
    }
    names := ""
    for pr in sel
        names .= pr.name " (" pr.pid ")`n"
    if MsgBox("End these processes?`n`n" names, APP_NAME, "YesNo Icon?") != "Yes"
        return
    for pr in sel {
        if IsProtected(pr.name) {
            LogMsg("Refused: " pr.name " is protected")
            continue
        }
        try {
            ProcessClose(pr.pid)
            LogMsg("Ended " pr.name " (" pr.pid ")")
        } catch as e {
            LogMsg("Could not end " pr.name ": " e.Message)
        }
    }
    RefreshProcs()
}

TrimSelected(*) {
    n := 0
    for pr in SelectedProcs() {
        if TrimPid(pr.pid)
            n++
    }
    LogMsg("Trimmed memory of " n " selected process(es)")
}

EcoSelected(state, *) {
    n := 0
    for pr in SelectedProcs() {
        if (IsProtected(pr.name))
            continue
        if SetEco(pr.pid, state) {
            n++
            if state
                S.throttled[pr.pid] := true
        }
    }
    LogMsg("Efficiency mode " (state ? "ON" : "OFF") " for " n " process(es)")
}

SetSelectedPriority(*) {
    lvl := C["prioDdl"].Text
    n := 0
    for pr in SelectedProcs() {
        if IsProtected(pr.name)
            continue
        try {
            ProcessSetPriority(lvl, pr.pid)
            n++
        }
    }
    LogMsg("Priority " lvl " set on " n " process(es)")
}

AddToTame(*) {
    added := 0
    for pr in SelectedProcs() {
        nm := StrLower(pr.name) ".exe"
        if (IsProtected(nm) || HasItem(ParseNames(Cfg["closer"]), nm))
            continue
        Cfg["closer"] := (Cfg["closer"] = "" ? "" : Cfg["closer"] ", ") nm
        added++
    }
    SaveSettings()
    C["cfg_closer"].Value := Cfg["closer"]
    LogMsg("Added " added " app(s) to the tame list")
}

; ================================================================ ROBLOX =====
EnableMulti() {
    if (S.mutexes.Length > 0)
        return
    for nm in ParseMutexNames(Cfg["mutexnames"]) {
        h := DllCall("CreateMutexW", "Ptr", 0, "Int", 1, "Str", nm, "Ptr")
        err := A_LastError
        if !h {
            LogMsg("Could not create mutex " nm " (error " err ")")
            continue
        }
        S.mutexes.Push(h)
        LogMsg("Holding mutex " nm (err = 183 ? "  (already existed: close ALL Roblox windows, then toggle this off and on)" : ""))
    }
    UpdateMultiStatus()
}

DisableMulti() {
    for h in S.mutexes
        DllCall("CloseHandle", "Ptr", h)
    if S.mutexes.Length
        LogMsg("Multi-instance off (mutex released)")
    S.mutexes := []
    UpdateMultiStatus()
}

UpdateMultiStatus() {
    if !C.Has("multiStat")
        return
    SetText(C["multiStat"], S.mutexes.Length ? "ON - holding " S.mutexes.Length " mutex handle(s). Launch Roblox again to open another client." : "Off")
}

OpenPS99(*) {
    try Run("roblox://experiences/start?placeId=" Integer(Cfg["placeid"]))
    catch
        LogMsg("Could not open Roblox - check the Place ID in Settings")
}

TileRoblox(*) {
    ids := WinGetList("ahk_exe " RobloxExe)
    n := ids.Length
    if !n {
        LogMsg("No Roblox windows found")
        return
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &tp, &rt, &bt)
    cols := Ceil(Sqrt(n))
    rows := Ceil(n / cols)
    w := (rt - l) // cols
    h := (bt - tp) // rows
    for i, id in ids {
        cx0 := Mod(i - 1, cols)
        ry0 := (i - 1) // cols
        try {
            WinRestore("ahk_id " id)
            WinMove(l + cx0 * w, tp + ry0 * h, w, h, "ahk_id " id)
        }
    }
    LogMsg("Tiled " n " Roblox window(s)")
}

CloseAllRoblox(*) {
    procs := RobloxProcs()
    if !procs.Length {
        LogMsg("Roblox is not running")
        return
    }
    if MsgBox("Close all " procs.Length " Roblox client(s)?", APP_NAME, "YesNo Icon?") != "Yes"
        return
    for pr in procs {
        try ProcessClose(pr.pid)
    }
    LogMsg("Closed Roblox client(s)")
}

RefreshInstances(procs := "") {
    if !IsObject(procs)
        procs := RobloxProcs()
    lv := C["lvInst"]
    lv.Delete()
    fg := 0
    try fg := WinGetPID("A")
    for pr in procs
        lv.Add(, pr.pid, Round(pr.ws / 1048576), (pr.pid = fg) ? "Focused" : "Background", pr.path)
    lv.ModifyCol(1, "Integer 70")
    lv.ModifyCol(2, "Integer 80")
    lv.ModifyCol(3, 90)
    lv.ModifyCol(4, 400)
}

LatestRobloxDir() {
    base := EnvGet("LocalAppData") "\Roblox\Versions"
    best := ""
    bestT := 0
    Loop Files, base "\*", "D" {
        if (FileExist(A_LoopFilePath "\" RobloxExe) && A_LoopFileTimeModified > bestT) {
            best := A_LoopFilePath
            bestT := A_LoopFileTimeModified
        }
    }
    return best
}

; Roblox only honours flags on its allow-list; others are ignored. The file is
; backed up first and "Remove flags" puts the original back.
ApplyFlags(silent := false) {
    dir := LatestRobloxDir()
    if (dir = "") {
        if !silent
            LogMsg("Roblox install not found in %LocalAppData%\Roblox\Versions")
        return
    }
    flags := Map()
    if Opt["ffps"] {
        cap := 240
        try cap := Max(30, Integer(Cfg["fpscap"]))
        flags["DFIntTaskSchedulerTargetFps"] := cap
    }
    if Opt["fpost"] {
        flags["FFlagDisablePostFx"] := "true"
    }
    if Opt["fquality"] {
        flags["DFIntDebugFRMQualityLevelOverride"] := 1
    }
    if Opt["fgrass"] {
        flags["FIntFRMMinGrassDistance"] := 0
        flags["FIntFRMMaxGrassDistance"] := 0
    }
    if Opt["ftex"] {
        flags["DFFlagTextureQualityOverrideEnabled"] := "true"
        flags["DFIntTextureQualityOverride"] := 0
    }
    if Opt["fd3d11"] {
        flags["FFlagDebugGraphicsPreferD3D11"] := "true"
    }
    if (flags.Count = 0) {
        if !silent
            LogMsg("No FastFlags ticked")
        return
    }
    parts := []
    for k, v in flags
        parts.Push('  "' k '": ' v)
    json := "{`n" JoinArr(parts, ",`n") "`n}"
    folder := dir "\ClientSettings"
    file := folder "\ClientAppSettings.json"
    bak := file ".ps99bak"
    mark := folder "\ClientAppSettings.ps99"
    try {
        if !DirExist(folder)
            DirCreate(folder)
        if (FileExist(file) && !FileExist(mark) && !FileExist(bak))
            FileCopy(file, bak)
        if FileExist(file)
            FileDelete(file)
        FileAppend(json, file, "UTF-8-RAW")
        FileAppend("written by " APP_NAME, mark)
        LogMsg("FastFlags written (" flags.Count " flag(s)) - they apply the next time Roblox starts")
    } catch as e {
        LogMsg("Could not write FastFlags: " e.Message)
    }
}

RemoveFlags(*) {
    base := EnvGet("LocalAppData") "\Roblox\Versions"
    n := 0
    Loop Files, base "\*", "D" {
        folder := A_LoopFilePath "\ClientSettings"
        file := folder "\ClientAppSettings.json"
        bak := file ".ps99bak"
        mark := folder "\ClientAppSettings.ps99"
        try {
            if FileExist(mark) {
                if FileExist(file)
                    FileDelete(file)
                FileDelete(mark)
                n++
            }
            if FileExist(bak)
                FileMove(bak, file, 1)
        }
    }
    LogMsg("FastFlags removed from " n " Roblox version folder(s)")
}

; ================================================================== TOOLS ====
DevMode(idx := -1) {
    buf := Buffer(220, 0)
    NumPut("UShort", 220, buf, 68)
    ok := DllCall("EnumDisplaySettingsW", "Ptr", 0, "UInt", idx & 0xFFFFFFFF, "Ptr", buf)
    return ok ? buf : ""
}

DisplayInfo() {
    cur := DevMode(-1)
    if !cur
        return {cur: 0, w: 0, h: 0, rates: []}
    w := NumGet(cur, 172, "UInt")
    h := NumGet(cur, 176, "UInt")
    bpp := NumGet(cur, 168, "UInt")
    hz := NumGet(cur, 184, "UInt")
    seen := Map()
    i := 0
    while (i < 4000) {
        md := DevMode(i)
        if !md
            break
        if (NumGet(md, 172, "UInt") = w && NumGet(md, 176, "UInt") = h && NumGet(md, 168, "UInt") = bpp) {
            rate := NumGet(md, 184, "UInt")
            if (rate > 1)
                seen[rate] := 1
        }
        i++
    }
    rates := []
    for rate, _ in seen
        rates.Push(rate)
    return {cur: hz, w: w, h: h, rates: rates}
}

SetRefresh(hz, track := true) {
    cur := DevMode(-1)
    if (!cur || hz < 2)
        return false
    if (track && !S.hzChanged) {
        S.prevHz := NumGet(cur, 184, "UInt")
        S.hzChanged := true
    }
    NumPut("UInt", hz, cur, 184)
    NumPut("UInt", 0x400000 | 0x80000 | 0x100000 | 0x40000, cur, 72)
    if (DllCall("ChangeDisplaySettingsW", "Ptr", cur, "UInt", 2, "Int") != 0) {
        LogMsg("Your display does not accept " hz " Hz at this resolution")
        return false
    }
    r := DllCall("ChangeDisplaySettingsW", "Ptr", cur, "UInt", 1, "Int")
    LogMsg(r = 0 ? "Refresh rate set to " hz " Hz" : "Refresh rate change failed (code " r ")")
    RefreshHzUi()
    return r = 0
}

RefreshHzUi() {
    if !C.Has("hzDdl")
        return
    info := DisplayInfo()
    SetText(C["hzTxt"], info.cur ? "Current: " info.w " x " info.h " @ " info.cur " Hz" : "Could not read the display mode")
    SetText(C["hwDisp"], info.cur ? "Display   " info.w " x " info.h " @ " info.cur " Hz" : "Display   unknown")
    ddl := C["hzDdl"]
    ddl.Delete()
    items := []
    pick := 0
    for i, rate in info.rates {
        items.Push("" rate)
        if (rate = info.cur)
            pick := i
    }
    if items.Length {
        ddl.Add(items)
        ddl.Choose(pick ? pick : items.Length)
    }
}

SetRefreshFromUi(*) {
    txt := C["hzDdl"].Text
    if (txt != "")
        SetRefresh(Integer(txt))
}

SetRefreshMax(*) {
    info := DisplayInfo()
    if info.rates.Length
        SetRefresh(info.rates[info.rates.Length])
}

ToggleClicker(*) {
    ToggleClickerForce(!S.clicking)
}

ToggleClickerForce(on) {
    if (on && !Opt["clicker"])
        return
    S.clicking := on
    if on {
        cps := 10
        try cps := Min(50, Max(1, Integer(Cfg["cps"])))
        SetTimer(ClickTick, Max(10, Round(1000 / cps)))
    } else {
        SetTimer(ClickTick, 0)
    }
    UpdateClickStatus()
}

ClickTick() {
    if (Opt["clickroblox"] && !WinActive("ahk_exe " RobloxExe))
        return
    Click()
}

UpdateClickStatus() {
    if !C.Has("clickStat")
        return
    if !Opt["clicker"]
        SetText(C["clickStat"], "Auto-clicker disabled")
    else
        SetText(C["clickStat"], S.clicking ? "CLICKING  (press F8 to stop)" : "Ready  (press F8 to start / stop)")
}

PingTest(*) {
    SetText(C["pingTxt"], "Pinging... (a few seconds)")
    Sleep(50)
    out := ""
    for host in ["1.1.1.1", "8.8.8.8", "www.roblox.com"] {
        res := Trim(ReadCmd("ping -n 3 -w 1500 " host), " `t`r`n")
        if RegExMatch(res, "(\d+)\s*ms$", &m)
            out .= host ": " m[1] " ms     "
        else
            out .= host ": no reply     "
    }
    SetText(C["pingTxt"], "Avg ping:  " out)
    LogMsg("Ping test: " out)
}

TogglePin(*) {
    try {
        WinSetAlwaysOnTop(-1, "A")
        LogMsg("Toggled always-on-top for the active window")
    }
}

SetStartWithWindows(on) {
    if on {
        exe := A_IsCompiled ? '\"' A_ScriptFullPath '\"' : '\"' A_AhkPath '\" \"' A_ScriptFullPath '\"'
        rc := RunWait('schtasks /create /tn "PS99Optimizer" /tr "' exe '" /sc onlogon /rl highest /f', , "Hide")
        LogMsg(rc = 0 ? "Will start with Windows (admin, no UAC prompt)" : "Could not create the startup task")
    } else {
        RunWait('schtasks /delete /tn "PS99Optimizer" /f', , "Hide")
        LogMsg("Start with Windows: off")
    }
}

; ================================================================ SCRIPTS ====
ListScripts(*) {
    lv := C["lvScripts"]
    lv.Delete()
    if !DirExist(ScriptsDir)
        DirCreate(ScriptsDir)
    seen := Map()
    Loop Files, ScriptsDir "\*.ahk", "R" {
        seen[A_LoopFileFullPath] := 1
        AddScriptRow(lv, A_LoopFileFullPath)
    }
    for pth in StrSplit(Cfg["extra"], "|") {
        if (pth != "" && FileExist(pth) && !seen.Has(pth))
            AddScriptRow(lv, pth)
    }
    lv.ModifyCol(1, 200)
    lv.ModifyCol(2, 80)
    lv.ModifyCol(3, 380)
}

AddScriptRow(lv, pth) {
    SplitPath(pth, &fname)
    running := S.scripts.Has(pth) && ProcessExist(S.scripts[pth])
    lv.Add(, fname, running ? "Running" : "Stopped", pth)
}

SelectedScript() {
    lv := C["lvScripts"]
    row := lv.GetNext(0)
    return row ? lv.GetText(row, 3) : ""
}

RunScript(pth) {
    if (pth = "")
        return
    if (S.scripts.Has(pth) && ProcessExist(S.scripts[pth])) {
        LogMsg("Already running: " pth)
        return
    }
    SplitPath(pth, , &dir)
    pid := 0
    try {
        if A_IsCompiled
            Run('"' pth '"', dir, , &pid)
        else
            Run('"' A_AhkPath '" "' pth '"', dir, , &pid)
        S.scripts[pth] := pid
        LogMsg("Launched " pth)
    } catch as e {
        LogMsg("Launch failed: " e.Message)
    }
    ListScripts()
}

RunSelectedScript(*) {
    RunScript(SelectedScript())
}

StopSelectedScript(*) {
    pth := SelectedScript()
    if (pth != "" && S.scripts.Has(pth) && ProcessExist(S.scripts[pth])) {
        try ProcessClose(S.scripts[pth])
        LogMsg("Stopped " pth)
    }
    Sleep(150)
    ListScripts()
}

EditSelectedScript(*) {
    pth := SelectedScript()
    if (pth != "")
        Run('notepad.exe "' pth '"')
}

OpenScriptsFolder(*) {
    if !DirExist(ScriptsDir)
        DirCreate(ScriptsDir)
    Run('explorer.exe "' ScriptsDir '"')
}

AddExternalScript(*) {
    pth := FileSelect(3, , "Add a script to the hub", "Scripts (*.ahk; *.txt; *.ahk2)")
    if (pth = "")
        return
    if !HasItem(StrSplit(Cfg["extra"], "|"), pth)
        Cfg["extra"] := (Cfg["extra"] = "" ? "" : Cfg["extra"] "|") pth
    SaveSettings()
    ListScripts()
}

RemoveExternalScript(*) {
    pth := SelectedScript()
    if (pth = "")
        return
    keep := []
    removed := false
    for item in StrSplit(Cfg["extra"], "|") {
        if (item = pth)
            removed := true
        else if (item != "")
            keep.Push(item)
    }
    if removed {
        Cfg["extra"] := JoinArr(keep, "|")
        SaveSettings()
        ListScripts()
    } else {
        LogMsg("That script lives in the Scripts folder - delete the file to remove it")
    }
}

; ================================================================ STATS ======
UpdateStats() {
    cpuNow := CpuLoad()
    mem := MemInfo()
    PushHist(S.cpuHist, cpuNow)
    PushHist(S.ramHist, mem.load)
    S.gpuTick += 1
    if (S.page = "Dashboard" && Mod(S.gpuTick, 4) = 1) {
        S.gpuLoad := GpuLoad()
        PushHist(S.gpuHist, Max(0, S.gpuLoad))
    }

    if (Opt["autotrim"] && !S.cleanBusy) {
        lim := 85
        try lim := Integer(Cfg["trimpct"])
        if (mem.load >= lim && A_TickCount - S.lastTrim > 90000) {
            S.lastTrim := A_TickCount
            LogMsg("RAM at " mem.load "% - auto-trimming")
            CleanRam(Opt["autostandby"])
        }
    }

    if (S.page = "Dashboard") {
        SetText(C["cpuTxt"], "CPU   " cpuNow "%")
        C["cpuBar"].Value := cpuNow
        SetText(C["cpuSpark"], Spark(S.cpuHist))
        SetText(C["ramTxt"], "RAM   " Round(mem.usedMB / 1024, 1) " / " Round(mem.totalMB / 1024, 1) " GB   (" mem.load "%)")
        C["ramBar"].Value := mem.load
        SetText(C["ramSpark"], Spark(S.ramHist))
        SetText(C["gpuTxt"], S.gpuLoad >= 0 ? "GPU   " S.gpuLoad "%  (3D engine)" : "GPU   not available")
        C["gpuBar"].Value := Max(0, S.gpuLoad)
        SetText(C["gpuSpark"], Spark(S.gpuHist))
        if S.rbxCount
            SetText(C["rbxTxt"], "ROBLOX   " S.rbxCount " client(s)   " S.rbxMB " MB   up " FmtDur(A_TickCount - S.rbxStart))
        else
            SetText(C["rbxTxt"], "ROBLOX   not running")
        SetText(C["sessTxt"], "Boost: " (S.boosted ? "ACTIVE for " FmtDur(A_TickCount - S.boostTick) : "off")
            . "     RAM freed this session: " Round(S.freedMB) " MB`nPeak Roblox memory: " S.peakRbxMB " MB     Optimizer running: " FmtDur(A_TickCount - S.startTick))
    } else if (S.page = "Cleaner") {
        SetText(C["cleanRam"], "RAM in use: " Round(mem.usedMB / 1024, 1) " / " Round(mem.totalMB / 1024, 1) " GB  (" mem.load "%)")
        C["cleanBar"].Value := mem.load
    }
}

Maintain() {
    procs := RobloxProcs()
    running := procs.Length > 0
    total := 0
    for pr in procs
        total += pr.ws
    S.rbxCount := procs.Length
    S.rbxMB := Round(total / 1048576)
    S.peakRbxMB := Max(S.peakRbxMB, S.rbxMB)
    if (running && !S.robloxWas) {
        S.robloxWas := true
        S.rbxStart := A_TickCount
        LogMsg("Roblox detected (" procs.Length " client(s))")
        if Opt["autoboost"]
            Apply()
    } else if (!running && S.robloxWas) {
        S.robloxWas := false
        LogMsg("Roblox closed after " FmtDur(A_TickCount - S.rbxStart))
        if Opt["flags"]
            ApplyFlags(true)
        if (Opt["autorevert"] && S.boosted)
            Revert()
    }
    if S.boosted
        TweakRoblox(procs)
    if (S.page = "Roblox")
        RefreshInstances(procs)
}

; ================================================================ GUI ========
PageAdd(page, type, opts, text := "") {
    ctl := G.Add(type, opts, text)
    if (page != "")
        Pages[page].Push(ctl)
    return ctl
}

Txt(page, opts, text, color, size := 9, bold := false, font := "Segoe UI") {
    ctl := G.Add("Text", opts " BackgroundTrans", text)
    ctl.SetFont("s" size (bold ? " Bold" : " Norm") " c" color, font)
    if (page != "")
        Pages[page].Push(ctl)
    return ctl
}

Hdr(page, y, text) {
    Txt(page, Format("x{} y{} w{} h22", CX, y, CW), text, T["accent"], 11, true)
    ln := G.Add("Text", Format("x{} y{} w{} h2 Background{}", CX, y + 26, CW, T["accent2"]))
    Pages[page].Push(ln)
}

Btn(page, x, y, w, h, text, fn, kind := "accent") {
    bg := T[kind]
    fg := (kind = "panel2") ? T["text"] : T["onAccent"]
    ctl := G.Add("Text", Format("x{} y{} w{} h{} Center +0x200 +0x100 Background{}", x, y, w, h, bg), text)
    ctl.SetFont("s9 Bold c" fg, "Segoe UI")
    ctl.OnEvent("Click", (*) => fn())
    HoverMap[ctl.Hwnd] := [bg, Lighten(bg)]
    if (page != "")
        Pages[page].Push(ctl)
    return ctl
}

AddOpt(page, x, y, w, key, label) {
    ctl := PageAdd(page, "Checkbox", Format("x{} y{} w{} h24 c{}{}", x, y, w, T["text"], Opt[key] ? " Checked" : ""), label)
    ctl.OnEvent("Click", OptToggled.Bind(key))
    Checks[key] := ctl
    return ctl
}

AddCfgEdit(page, x, y, w, key, extra := "") {
    ed := PageAdd(page, "Edit", Format("x{} y{} w{} h24 Background{} c{} {}", x, y, w, T["panel"], T["text"], extra), Cfg[key])
    ed.OnEvent("Change", CfgChanged.Bind(key))
    C["cfg_" key] := ed
    return ed
}

AddList(page, x, y, w, h, cols) {
    return PageAdd(page, "ListView", Format("x{} y{} w{} h{} Background{} c{}", x, y, w, h, T["panel"], T["text"]), cols)
}

OnMouseMove(wParam, lParam, msg, hwnd) {
    h := 0
    try MouseGetPos(, , , &h, 2)
    if (h = S.lastHover)
        return
    if (S.lastHover && HoverMap.Has(S.lastHover))
        SetCtlBg(S.lastHover, HoverMap[S.lastHover][1])
    S.lastHover := h
    if (h && HoverMap.Has(h))
        SetCtlBg(h, HoverMap[h][2])
}

SetCtlBg(hwnd, color) {
    try {
        ctl := GuiCtrlFromHwnd(hwnd)
        ctl.Opt("Background" color)
        ctl.Redraw()
    }
}

ShowPage(name, *) {
    S.page := name
    for pn, arr in Pages {
        vis := (pn = name)
        for ctl in arr
            ctl.Visible := vis
    }
    for i, nm in NavNames {
        nb := NavBtns[nm]
        active := (nm = name)
        bg := active ? T["panel2"] : T["side"]
        nb.Opt("Background" bg)
        nb.SetFont("s15 Bold c" (active ? T["accent"] : T["dim"]), "Gabriola")
        HoverMap[nb.Hwnd] := [bg, active ? bg : T["panel"]]
        nb.Redraw()
        if active
            C["navBar"].Move(0, 84 + (i - 1) * 42)
    }
    if (name = "Processes")
        RefreshProcs()
    else if (name = "Scripts")
        ListScripts()
    else if (name = "Roblox") {
        RefreshInstances()
        UpdateMultiStatus()
    } else if (name = "Tools") {
        RefreshHzUi()
        UpdateClickStatus()
    }
    UpdateStats()
}

BuildGui() {
    global G
    G := Gui("-MaximizeBox", APP_NAME " " APP_VER)
    G.BackColor := T["bg"]
    G.MarginX := 0
    G.MarginY := 0
    G.SetFont("s9", "Segoe UI")
    G.OnEvent("Close", OnGuiClose)
    for nm in NavNames
        Pages[nm] := []

    dark := Buffer(4, 0)
    NumPut("Int", 1, dark)
    if (DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", G.Hwnd, "Int", 20, "Ptr", dark, "Int", 4) != 0)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", G.Hwnd, "Int", 19, "Ptr", dark, "Int", 4)

    ; sidebar
    G.Add("Text", "x0 y0 w180 h625 Background" T["side"])
    Txt("", "x22 y14 w150 h36", "(•˕ •マ.ᐟ", T["accent"], 18, true, "Cambria Black")	
    Txt("", "x24 y52 w150 h18", "Mila's RoBooster", T["accent2"], 8, true)
    for i, nm in NavNames {
        nb := G.Add("Text", Format("x0 y{} w180 h38 +0x200 +0x100 Background{}", 84 + (i - 1) * 42, T["side"]), "    " NavIcons[nm] "   " nm)
        nb.SetFont("s10 c" T["dim"], "Segoe UI")
        nb.OnEvent("Click", ShowPage.Bind(nm))
        NavBtns[nm] := nb
    }
    C["navBar"] := G.Add("Text", "x0 y84 w4 h38 Background" T["accent"])
    Txt("", "x22 y588 w150 h18", " " APP_VER "   |   Milamoo12340", T["dim"], 8)

    BuildDashboard()
    BuildBoost()
    BuildCleaner()
    BuildProcesses()
    BuildRoblox()
    BuildTools()
    BuildScripts()
    BuildSettings()
		
    ; activity log (always visible)
    Txt("", Format("x{} y474 w300 h18", CX), "ACTIVITY LOG", T["accent"], 8, true)
    C["log"] := G.Add("Edit", Format("x{} y494 w{} h120 ReadOnly Multi +VScroll Background{} c{}", CX, CW, T["panel"], T["text"]))
    C["log"].SetFont("s8 c" T["text"], "Consolas")
}

OnGuiClose(*) {
    if Opt["closetray"] {
        G.Hide()
        return true
    }
    ExitApp()
}

BuildDashboard() {
    pg := "Dashboard"
    Hdr(pg, 68, " (˵◝ ⩊  ◜˵マ  SYSTEM OVERVIEW  (˵◝ ⩊  ◜˵マ ")
    Txt(pg, Format("x{} y108 w{} h18", CX, CW), "CPU   " S.cpuName, T["text"])
    Txt(pg, Format("x{} y128 w{} h18", CX, CW), "GPU   " S.gpuName, T["text"])
    Txt(pg, Format("x{} y148 w{} h18", CX, CW), "RAM   " S.totalRamGB " GB      " S.osName, T["text"])
    C["hwDisp"] := Txt(pg, Format("x{} y168 w{} h18", CX, CW), "Display   ...", T["text"])
    meters := [["cpu", 202], ["ram", 252], ["gpu", 302]]
    for m in meters {
        id := m[1]
        yy := m[2]
        C[id "Txt"] := Txt(pg, Format("x{} y{} w310 h20", CX, yy), "", T["text"], 10, true)
        C[id "Bar"] := PageAdd(pg, "Progress", Format("x{} y{} w300 h12 -Theme c{} Background{}", CX, yy + 26, T["accent"], T["panel2"]))
        C[id "Spark"] := Txt(pg, Format("x{} y{} w350 h30", CX + 320, yy), "", T["accent2"], 12, false, "Segoe UI Symbol")
    }
    C["rbxTxt"] := Txt(pg, Format("x{} y352 w{} h22", CX, CW), "ROBLOX   not running", T["good"], 11, true)
    C["sessTxt"] := Txt(pg, Format("x{} y380 w{} h36", CX, CW), "", T["dim"], 9)
    Btn(pg, CX, 426, 210, 38, "BOOST NOW", BoostNow, "accent")
    Btn(pg, CX + 230, 426, 210, 38, "CLEAN RAM", () => CleanRam(true), "accent2")
    Btn(pg, CX + 460, 426, 210, 38, "REVERT ALL", Revert, "bad")
}

BuildBoost() {
    pg := "Boost"
    Hdr(pg, 68, "🐺 BOOST PROFILE 🐺  -  every change is reversible (•˕ •マⳊ ")
    presetNames := ["Balanced", "Max FPS", "Cool and Quiet", "Multi-box"]
    for i, pn in presetNames
        Btn(pg, CX + (i - 1) * 170, 108, 160, 28, pn, ApplyPreset.Bind(pn), "panel2")
    items := [
        ["priority", "Roblox: High CPU priority"],
        ["focusprio", "Smart priority (focused High, others Low)"],
        ["power", "High-performance power plan"],
        ["ultimate", "    ...use Ultimate Performance instead"],
        ["cool", "Cool mode: cap CPU at 99% (no turbo)"],
        ["timer", "0.5 ms timer resolution"],
        ["gpu", "Roblox: high-performance GPU"],
        ["gamemode", "Windows Game Mode on"],
        ["dvr", "Disable Game DVR background capture"],
        ["fso", "Disable fullscreen optimizations"],
        ["services", "Pause SysMain / Search / telemetry"],
        ["antiidle", "Anti-idle keypress (Roblox only)"]
    ]
    for i, it in items {
        colX := (i > 6) ? 340 : 0
        rowY := Mod(i - 1, 6)
        AddOpt(pg, CX + colX, 150 + rowY * 28, 325, it[1], it[2])
    }
    Txt(pg, Format("x{} y330 w{} h18", CX, CW), "Background apps to tame (comma separated, e.g. msedge.exe, chrome.exe):", T["dim"])
    AddCfgEdit(pg, CX, 352, 430, "closer")
    ddl := PageAdd(pg, "DropDownList", Format("x{} y352 w110 Choose{}", CX + 445, Cfg["closermode"] = "Close" ? 2 : 1), ["Throttle", "Close"])
    ddl.OnEvent("Change", ModeChanged)
    AddOpt(pg, CX, 384, 600, "throttle", "Tame those apps whenever the boost is applied")
    Btn(pg, CX, 424, 210, 36, "APPLY BOOST", Apply, "accent")
    Btn(pg, CX + 230, 424, 210, 36, "REVERT ALL", Revert, "bad")
    Btn(pg, CX + 460, 424, 210, 36, "CREATE RESTORE POINT", RestorePoint, "panel2")
}

BuildCleaner() {
    pg := "Cleaner"
    Hdr(pg, 68, " ฅ^•ﻌ•^ฅ  MEMORY AND DISK CLEANUP ฅ^•ﻌ•^ฅ ")
    C["cleanRam"] := Txt(pg, Format("x{} y108 w{} h20", CX, CW), "", T["text"], 10, true)
    C["cleanBar"] := PageAdd(pg, "Progress", Format("x{} y132 w400 h12 -Theme c{} Background{}", CX, T["accent"], T["panel2"]))
    Btn(pg, CX, 162, 210, 36, "TRIM BACKGROUND APPS", () => CleanRam(false), "accent")
    Btn(pg, CX + 230, 162, 210, 36, "PURGE STANDBY LIST", () => (PurgeStandby(), SetResult("Standby list purged")), "accent")
    Btn(pg, CX + 460, 162, 210, 36, "CLEAN ALL RAM", () => CleanRam(true), "accent2")
    Btn(pg, CX, 208, 210, 36, "CLEAN TEMP FILES", CleanTemp, "panel2")
    Btn(pg, CX + 230, 208, 210, 36, "CLEAN ROBLOX LOGS", CleanRobloxLogs, "panel2")
    Btn(pg, CX + 460, 208, 210, 36, "FLUSH DNS", FlushDns, "panel2")
    C["cleanResult"] := Txt(pg, Format("x{} y254 w{} h36", CX, CW), "Last result: nothing yet", T["good"], 9, true)
    Hdr(pg, 296, "AUTOMATION")
    AddOpt(pg, CX, 338, 300, "autotrim", "Auto-trim when RAM usage is above")
    AddCfgEdit(pg, CX + 305, 336, 50, "trimpct", "+Number")
    Txt(pg, Format("x{} y340 w30 h20", CX + 362), "%", T["text"])
    AddOpt(pg, CX, 368, 500, "autostandby", "Also purge the standby list during auto-trim")
    Txt(pg, Format("x{} y404 w{} h50", CX, CW), "Trimming moves idle memory of background apps to the page file. It frees RAM fast, but those apps can feel slower for a moment when you switch back. Roblox itself is never trimmed.", T["dim"], 8)
}

BuildProcesses() {
    pg := "Processes"
    Hdr(pg, 68, " ₍^. .^₎Ⳋ PROCESSES ₍^. .^₎Ⳋ  -  sort them by clicking a column ")
    C["lvProc"] := AddList(pg, CX, 104, CW, 252, ["Process", "PID", "CPU %", "RAM MB"])
    Btn(pg, CX, 366, 126, 28, "REFRESH", RefreshProcs, "panel2")
    Btn(pg, CX + 136, 366, 126, 28, "END PROCESS", EndSelected, "bad")
    Btn(pg, CX + 272, 366, 126, 28, "TRIM MEMORY", TrimSelected, "accent")
    Btn(pg, CX + 408, 366, 126, 28, "ECO MODE ON", EcoSelected.Bind(1), "accent2")
    Btn(pg, CX + 544, 366, 126, 28, "ECO MODE OFF", EcoSelected.Bind(0), "panel2")
    Txt(pg, Format("x{} y412 w60 h20", CX), "Priority", T["dim"])
    C["prioDdl"] := PageAdd(pg, "DropDownList", Format("x{} y408 w130 Choose3", CX + 60), ["Low", "BelowNormal", "Normal", "AboveNormal", "High"])
    Btn(pg, CX + 200, 406, 126, 28, "SET PRIORITY", SetSelectedPriority, "panel2")
    Btn(pg, CX + 336, 406, 160, 28, "ADD TO TAME LIST", AddToTame, "panel2")
    Txt(pg, Format("x{} y440 w{} h20", CX, CW), "Eco mode = Windows Efficiency mode (lower clocks and priority for that app). System processes are protected.", T["dim"], 8)
}

BuildRoblox() {
    pg := "Roblox"
    Hdr(pg, 68, " ⪩ ⪨ ROBLOX TOOLS ⪩ ⪨ -  multi-instance and windows")
    AddOpt(pg, CX, 106, 670, "multi", "Enable multi-instance (claim Roblox's singleton mutex so more clients can start)")
    Txt(pg, Format("x{} y141 w95 h20", CX), "Mutex names", T["dim"])
    AddCfgEdit(pg, CX + 95, 137, 575, "mutexnames")
    C["multiStat"] := Txt(pg, Format("x{} y166 w{} h18", CX, CW), "", T["good"], 9, true)
    Btn(pg, CX, 192, 210, 32, "OPEN PS99", OpenPS99, "accent")
    Btn(pg, CX + 230, 192, 210, 32, "TILE ROBLOX WINDOWS", TileRoblox, "panel2")
    Btn(pg, CX + 460, 192, 210, 32, "CLOSE ALL ROBLOX", CloseAllRoblox, "bad")
    Txt(pg, Format("x{} y236 w300 h18", CX), "RUNNING INSTANCES", T["accent"], 9, true)
    C["lvInst"] := AddList(pg, CX, 256, CW, 88, ["PID", "RAM MB", "State", "Path"])
    Txt(pg, Format("x{} y354 w{} h18", CX, CW), "FASTFLAGS  (written to the newest Roblox version, backed up first)", T["accent"], 9, true)
    flagItems := [["ffps", "Unlock FPS cap"], ["fpost", "Disable post-processing"], ["fquality", "Lower quality level"],
        ["fgrass", "No grass"], ["ftex", "Low textures"], ["fd3d11", "Prefer Direct3D 11"]]
    for i, fi in flagItems {
        AddOpt(pg, CX + Mod(i - 1, 3) * 225, 376 + ((i - 1) // 3) * 26, 215, fi[1], fi[2])
    }
    Txt(pg, Format("x{} y434 w60 h20", CX), "FPS cap", T["dim"])
    AddCfgEdit(pg, CX + 60, 430, 60, "fpscap", "+Number")
    Btn(pg, CX + 135, 428, 150, 28, "WRITE FLAGS", () => ApplyFlags(), "accent")
    Btn(pg, CX + 295, 428, 150, 28, "REMOVE FLAGS", RemoveFlags, "panel2")
    AddOpt(pg, CX + 455, 430, 215, "flags", "Keep flags applied")
}

BuildTools() {
    pg := "Tools"
    Hdr(pg, 68, " ≽^•⩊•^≼ DISPLAY ≽^•⩊•^≼ ")
    C["hzTxt"] := Txt(pg, Format("x{} y110 w260 h20", CX), "", T["text"], 10, true)
    C["hzDdl"] := PageAdd(pg, "DropDownList", Format("x{} y106 w100", CX + 280), [])
    Btn(pg, CX + 395, 106, 120, 26, "SET", SetRefreshFromUi, "accent")
    Btn(pg, CX + 525, 106, 120, 26, "SET MAX", SetRefreshMax, "accent2")
    Hdr(pg, 146, "AUTO-CLICKER   (hotkey F8)")
    AddOpt(pg, CX, 186, 300, "clicker", "Enable the F8 toggle")
    Txt(pg, Format("x{} y190 w90 h20", CX + 320), "Clicks / sec", T["dim"])
    AddCfgEdit(pg, CX + 410, 186, 50, "cps", "+Number")
    AddOpt(pg, CX, 214, 500, "clickroblox", "Only click while Roblox is the focused window")
    C["clickStat"] := Txt(pg, Format("x{} y244 w{} h20", CX, CW), "", T["good"], 9, true)
    Hdr(pg, 274, "NETWORK")
    Btn(pg, CX, 312, 160, 30, "PING TEST", PingTest, "accent")
    Btn(pg, CX + 170, 312, 160, 30, "FLUSH DNS", FlushDns, "panel2")
    C["pingTxt"] := Txt(pg, Format("x{} y350 w{} h20", CX, CW), "", T["text"], 9)
    Hdr(pg, 380, "WINDOWS SHORTCUTS")
    short := [["TASK MANAGER", "taskmgr.exe"], ["RESOURCE MON", "resmon.exe"], ["GPU SETTINGS", "ms-settings:display-advancedgraphics"],
        ["DISPLAY", "ms-settings:display"], ["POWER", "ms-settings:powersleep"], ["STARTUP APPS", "ms-settings:startupapps"]]
    for i, sc in short
        Btn(pg, CX + (i - 1) * 112, 420, 104, 28, sc[1], RunQuick.Bind(sc[2]), "panel2")
}

RunQuick(target, *) {
    try Run(target)
}

BuildScripts() {
    pg := "Scripts"
    Hdr(pg, 68, "MACRO HUB ⢏⢢⣀⡔⡹  -  Store your personal macros here for quick launching") 
    C["lvScripts"] := AddList(pg, CX, 104, CW, 240, ["Script", "Status", "Path"])
    C["lvScripts"].OnEvent("DoubleClick", RunSelectedScript)
    Btn(pg, CX, 354, 160, 30, "RUN", RunSelectedScript, "accent")
    Btn(pg, CX + 170, 354, 160, 30, "STOP", StopSelectedScript, "bad")
    Btn(pg, CX + 340, 354, 160, 30, "EDIT", EditSelectedScript, "panel2")
    Btn(pg, CX + 510, 354, 160, 30, "OPEN FOLDER", OpenScriptsFolder, "panel2")
    Btn(pg, CX, 394, 210, 30, "ADD SCRIPT...", AddExternalScript, "accent2")
    Btn(pg, CX + 230, 394, 210, 30, "REMOVE FROM LIST", RemoveExternalScript, "panel2")
    Btn(pg, CX + 460, 394, 210, 30, "REFRESH", ListScripts, "panel2")
    Txt(pg, Format("x{} y434 w{} h34", CX, CW), "Drop .ahk files into the Scripts folder next to this app, or add any script from anywhere (macros, utilities, other tools). Each one runs in its own process with AutoHotkey v2.", T["dim"], 8)
}

BuildSettings() {
    pg := "Settings"
    Hdr(pg, 68, " ♡🐾 APP SETTINGS ♡🐾 ")
    Txt(pg, Format("x{} y112 w60 h20", CX), "Theme", T["dim"])
    themeNames := ["Neon", "Sunset", "Ocean", "Matrix", "Violet"]
    pick := 1
    for i, tn in themeNames {
        if (tn = Cfg["theme"])
            pick := i
    }
    C["themeDdl"] := PageAdd(pg, "DropDownList", Format("x{} y108 w140 Choose{}", CX + 60, pick), themeNames)
    Btn(pg, CX + 215, 107, 160, 26, "APPLY THEME", ApplyTheme, "accent")
    AddOpt(pg, CX, 150, 600, "autoboost", "Auto-boost when Roblox launches")
    AddOpt(pg, CX, 178, 600, "autorevert", "Auto-revert when Roblox closes")
    AddOpt(pg, CX, 206, 600, "revertonexit", "Revert everything when this app exits")
    AddOpt(pg, CX, 234, 600, "closetray", "Close button hides to the system tray")
    AddOpt(pg, CX, 262, 600, "startwin", "Start with Windows (admin, no UAC prompt)")
    Txt(pg, Format("x{} y304 w200 h20", CX), "Anti-idle interval (min)", T["dim"])
    AddCfgEdit(pg, CX + 210, 300, 60, "idlemin", "+Number")
    Txt(pg, Format("x{} y334 w200 h20", CX), "PS99 Place ID", T["dim"])
    AddCfgEdit(pg, CX + 210, 330, 160, "placeid", "+Number")
    Txt(pg, Format("x{} y364 w200 h20", CX), "Services to pause (| separated)", T["dim"])
    AddCfgEdit(pg, CX + 210, 360, 300, "services")
    Btn(pg, CX, 402, 210, 30, "OPEN LOG", () => Run('notepad.exe "' LogFile '"'), "panel2")
    Btn(pg, CX + 230, 402, 210, 30, "OPEN APP FOLDER", () => Run('explorer.exe "' A_ScriptDir '"'), "panel2")
    Btn(pg, CX + 460, 402, 210, 30, "RESET SETTINGS", ResetSettings, "bad")
    Txt(pg, Format("x{} y444 w{} h20", CX, CW), "Hotkeys:  Ctrl+Alt+B boost   Ctrl+Alt+C clean RAM   Ctrl+Alt+O show/hide   Ctrl+Alt+T pin window on top   F8 auto-clicker", T["dim"], 8)
}

ApplyTheme(*) {
    Cfg["theme"] := C["themeDdl"].Text
    SaveSettings()
    Reload()
}

ResetSettings(*) {
    if MsgBox("Reset all options to their defaults? (Undo data for the registry is kept.)", APP_NAME, "YesNo Icon?") != "Yes"
        return
    try IniDelete(IniFile, "options")
    try IniDelete(IniFile, "config")
    Reload()
}

; ============================================================ TRAY / HOTKEYS ==
BuildTray() {
    A_IconTip := APP_NAME
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show / hide", ToggleGui)
    A_TrayMenu.Add("Boost now", BoostNow)
    A_TrayMenu.Add("Clean RAM", (*) => CleanRam(true))
    A_TrayMenu.Add("Revert all", Revert)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.Default := "Show / hide"
    A_TrayMenu.ClickCount := 1
}

ToggleGui(*) {
    if DllCall("IsWindowVisible", "Ptr", G.Hwnd) {
        G.Hide()
    } else {
        G.Show()
        WinActivate("ahk_id " G.Hwnd)
    }
}

RegisterHotkeys() {
    Hotkey("^!b", BoostNow)
    Hotkey("^!c", (*) => CleanRam(true))
    Hotkey("^!o", ToggleGui)
    Hotkey("^!t", TogglePin)
    Hotkey("F8", ToggleClicker, "Off")
}

ExitCleanup(reason, code) {
    try {
        if (S.boosted && Opt["revertonexit"])
            Revert()
    }
    for h in S.mutexes
        DllCall("CloseHandle", "Ptr", h)
}

; ================================================================ START ======
LoadSettings()
T := Themes[Cfg["theme"]]
S.wmi := ComObjGet("winmgmts:")
DetectHardware()
BuildGui()
BuildTray()
RegisterHotkeys()
OnExit(ExitCleanup)
OnMessage(0x200, OnMouseMove)
if Opt["multi"]
    EnableMulti()
if Opt["flags"]
    ApplyFlags(true)
if Opt["clicker"]
    Hotkey("F8", "On")
RefreshHzUi()
SetTimer(UpdateStats, 1500)
SetTimer(Maintain, 5000)
Maintain()
ShowPage("Dashboard")
G.Show("w900 h625")
LogMsg(APP_NAME " " APP_VER " ready  |  " S.cores " threads  |  " S.totalRamGB " GB RAM")
