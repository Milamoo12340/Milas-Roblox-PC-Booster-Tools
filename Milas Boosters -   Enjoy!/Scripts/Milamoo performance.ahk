; ==============================================================================
; 😻 PS99 ULTIMATE POTATO OPTIMIZER: FINAL EDITION 😻
; Merges: Original Features + Deep Dive Fixes + Network + GPU + Refresh Rate
; ==============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp
}

; --- 1. ADMINISTRATOR CHECK ---
if not A_IsAdmin {
    try {
        Run "*RunAs " A_ScriptFullPath
    } catch {
        MsgBox("Admin rights needed for Registry & Service optimizations!", "Admin Required", "Icon!")
    }
    ExitApp
}

; --- 2. GLOBAL CONFIGURATION ---
global MainLog := ""
global CurrentBrightness := 50
global TargetProcess := "RobloxPlayerBeta.exe"
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
OnExit(ExitCleanup)
Apply()
SetTimer(Maintain, 15000)
Log("Helper started. " Cores " threads, " RamGB " GB RAM")

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

; --- 3. INITIALIZATION & GUI ---
InitializeOptimizer()

InitializeOptimizer() {
    DetectHardware()
    CreateGUI()
}

DetectHardware() {
    global Cores, RamBG, CPUName := "Detecting...", GPUName := "Detecting..."
    try {
        for cpu in ComObjGet("winmgmts:").ExecQuery("SELECT NumberOfLogicalProcessors FROM Win32_Processor")
            Cores := cpu.NumberOfLogicalProcessors
        for cs in ComObjGet("winmgmts:").ExecQuery("SELECT TotalPhysicalMemory FROM Win32_ComputerSystem")
            RamGB := Round(cs.TotalPhysicalMemory / 1073741824, 1)
        for obj in ComObjGet("winmgmts:").ExecQuery("SELECT Name FROM Win32_Processor")
            CPUName := obj.Name
        for obj in ComObjGet("winmgmts:").ExecQuery("SELECT Name FROM Win32_VideoController WHERE PNPDeviceID LIKE 'PCI%'")
            GPUName := obj.Name
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

CreateGUI() {
    global
    OptimizerGui := Gui("+Resize +AlwaysOnTop", "😻 Milamoo's PS99 Ultimate Optimizer 😻")
    OptimizerGui.BackColor := "1E1E1E"
    OptimizerGui.SetFont("s8 Bold q5 cLime", "Segoe Print")

    ; Hardware Header

    OptimizerGui.Add("Text", "x10 y10 w400 Center", "Hardware Detected").SetFont("s9 Bold Underline q5 cYellow")
    OptimizerGui.Add("Text", "x20 y35", "CPU: " . CPUName).SetFont("s8 Bold")
    OptimizerGui.Add("Text", "x20 y50", "GPU: " . GPUName).SetFont("s8 Bold")

    ; --- SECTION 1: SYSTEM CORE ---
    OptimizerGui.Add("Text", "x10 y80 w400 Center", "--- System Core ---").SetFont("s10 Bold q5 cAqua Underline")
    
    BtnPower := OptimizerGui.Add("Button", "x10 y105 w190 h30", "1. Fix Power/Heat (99%)")
    BtnPower.OnEvent("Click", ApplyPotatoPowerPlan)

    BtnTimer := OptimizerGui.Add("Button", "x210 y105 w190 h30", "2. Max Timer Res (0.5ms)")
    BtnTimer.OnEvent("Click", SetMaxTimerResolution)

    BtnSvcs := OptimizerGui.Add("Button", "x10 y140 w190 h30", "3. Debloat Services")
    BtnSvcs.OnEvent("Click", StopBloatServices)

    BtnRam := OptimizerGui.Add("Button", "x210 y140 w190 h30", "4. Flush RAM (EmptySet)")
    BtnRam.OnEvent("Click", FlushMemory)

    ; --- SECTION 2: GAMING & GPU ---
    OptimizerGui.Add("Text", "x10 y180 w400 Center", "--- Gaming, GPU & Network ---").SetFont("s10 Bold q5 cRed Underline")

    BtnFlags := OptimizerGui.Add("Button", "x10 y205 w190 h30", "5. Inject Roblox FastFlags")
    BtnFlags.OnEvent("Click", InjectFastFlags)

    BtnGameMode := OptimizerGui.Add("Button", "x210 y205 w190 h30", "6. Force Game Mode + FSO")
    BtnGameMode.OnEvent("Click", OptimizeGamingRegistry)

    BtnNet := OptimizerGui.Add("Button", "x10 y240 w190 h30", "7. Optimize Network/TCP")
    BtnNet.OnEvent("Click", OptimizeNetwork)

    BtnHz := OptimizerGui.Add("Button", "x210 y240 w190 h30", "8. Max Monitor Refresh Rate")
    BtnHz.OnEvent("Click", MaximizeRefreshRate)

    ; --- MASTER CONTROLS ---
    BtnAll := OptimizerGui.Add("Button", "x10 y285 w400 h45 BackgroundGreen", "🚀 ACTIVATE ALL GOD MODE SETTINGS 🚀")
    BtnAll.SetFont("s12 Bold")
    BtnAll.OnEvent("Click", RunAllOptimizations)

    ; Log
    MainLog := OptimizerGui.Add("Edit", "x10 y340 w400 h120 ReadOnly Background000000 c00FF00 vLogOutput", "Waiting for command...")
    
    OptimizerGui.Show("w420 h470")
}

Log(Text) {
    try {
        MainLog.Value .= "`r`n[" A_Hour ":" A_Min ":" A_Sec "] " Text
        SendMessage(0x0115, 7, 0, MainLog.Hwnd, "AutoHotkeyGUI")
    }
}

RunAllOptimizations(*) {
    Log(">>> STARTING ULTIMATE OPTIMIZATION SEQUENCE <<<")
    ApplyPotatoPowerPlan()
    SetMaxTimerResolution()
    StopBloatServices()
    FlushMemory()
    InjectFastFlags()
    OptimizeGamingRegistry()
    OptimizeNetwork()
    MaximizeRefreshRate()
    Log(">>> ✅ GOD MODE ENABLED: RESTART GAME! <<<")
}

Apply(*) {
    global Opt, PowerApplied, TimerApplied, AntiIdleOn, ServiceNames, StoppedSvcs
    if Opt["power"] && !PowerApplied {
        ApplyPower()
    }
    if Opt["timer"] && !TimerApplied {
        DllCall("winmm\timeBeginPeriod", "UInt", 1)
        TimerApplied := true
        Log("Timer resolution set to 1 ms")
    }
    if Opt["services"] && StoppedSvcs.Length = 0 {
        for name in ServiceNames {
            RunWait("cmd /c sc stop " name, , "Hide")
            StoppedSvcs.Push(name)
            Log("Stopped service: " name)
        }
    }
    if Opt["antiidle"] && !AntiIdleOn {
        AntiIdleOn := true
        SetTimer(AntiIdle, 540000)
        Log("Anti-idle on: Space every 9 minutes while Roblox is the active window")
    }
    Maintain()
}

ActivePlan() {
    out := ReadCmd("powercfg /getactivescheme")
    if RegExMatch(out, "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", &m)
        return m[0]
    return ""
}

ApplyPower() {
    global OrigPlan, PowerApplied, HighPerfGuid
    OrigPlan := ActivePlan()
    RunWait("cmd /c powercfg /setactive " HighPerfGuid, , "Hide")
    PowerApplied := true
    Log("Power plan: switched to High performance (was " OrigPlan ")")
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
                Log("GPU preference set to high performance for " p.path)
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
WinWait Roblox 
IfWinNotActive Roblox, , WinActivate, Roblox 
WinWaitActive Roblox 
    if WinActive("ahk_exe " RobloxExe, Roblox)
        Send("{Space}")
        Sleep 540000
}

; ------------------------------------------------------------------- revert ---
Revert() {
    global OrigPlan, PowerApplied, TimerApplied, AntiIdleOn, StoppedSvcs, GpuSet, HighPerfGuid
    if PowerApplied && OrigPlan != "" {
        RunWait("cmd /c powercfg /setactive " OrigPlan, , "Hide")
        Log("Power plan restored to " OrigPlan)
    }
    PowerApplied := false
    if TimerApplied {
        DllCall("winmm\timeEndPeriod", "UInt", 1)
        TimerApplied := false
        Log("Timer resolution restored")
    }
    for name in StoppedSvcs {
        RunWait("cmd /c sc config " name " start= auto", , "Hide")
        RunWait("cmd /c sc start " name, , "Hide")
        Log("Restarted service: " name)
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
    Log("Everything reverted")
    if IsObject(StatusText)
        StatusText.Value := "Reverted. Press Apply to turn options back on."
}

ExitCleanup(*) {
    global TimerApplied
    if TimerApplied
        DllCall("winmm\timeEndPeriod", "UInt", 1)
}


; ==============================================================================
; [CORE 1] POWER PLAN (The 99% Heat Fix + Brightness Lock)
; ==============================================================================
ApplyPotatoPowerPlan(*) {
    Log("[Power] Initiating 99% CPU Cap (No Throttling)...")
    try {
        For item in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM WmiMonitorBrightness")
            CurrentBrightness := item.CurrentBrightness
    }
    
    ; Create & Activate Plan
    RunWait("powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 99999999-9999-9999-9999-999999999999",, "Hide")
    RunWait("powercfg -changename 99999999-9999-9999-9999-999999999999 'PS99 Ultimate'",, "Hide")
    RunWait("powercfg -setactive 99999999-9999-9999-9999-999999999999",, "Hide")
    
    ; Set Max CPU to 99% (Disables Turbo Boost/Heat)
    RunWait("powercfg -setacvalueindex scheme_current sub_processor bc5038f7-23e0-4960-96da-33abaf5935ec 99",, "Hide") 
    ; Set Min CPU to 80% (Prevents lag spikes from parking)
    RunWait("powercfg -setacvalueindex scheme_current sub_processor 893dee8e-2bef-41e0-89c6-b55d0929964c 80",, "Hide")
    RunWait("powercfg -setactive scheme_current",, "Hide")

    try {
        For item in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods")
            item.WmiSetBrightness(1, CurrentBrightness)
    }
    Log("[Power] ✓ Done. Turbo Boost disabled (Cooler PC).")
}

; ==============================================================================
; [CORE 2] TIMER RESOLUTION (0.5ms Latency)
; ==============================================================================
SetMaxTimerResolution(*) {
    ; Uses NTDLL to request 0.5ms timer resolution (Standard Windows is 15.6ms)
    try {
        DllCall("ntdll\NtSetTimerResolution", "UInt", 5000, "Int", 1, "UInt*", &CurrentRes := 0)
        Log("[Timer] ✓ Forced System Timer to 0.5ms (Max Responsiveness)")
    } catch as e {
        Log("[Timer] ⚠ Failed to set timer: " e.Message)
    }
}

; ==============================================================================
; [CORE 3] DEBLOAT SERVICES
; ==============================================================================
StopBloatServices(*) {
    Log("[Services] Stopping resource hogs...")
    Services := ["SysMain", "DiagTrack", "MapsBroker", "PcaSvc", "WerSvc", "Spooler", "OneDrive*", ]
    for svc in Services {
        RunWait("sc stop " svc, , "Hide")
        RunWait("sc config " svc " start= demand", , "Hide")
    }
    Log("[Services] ✓ Telemetry, Print Spooler & SysMain paused.")
}

; ==============================================================================
; [CORE 4] RAM FLUSH (Native API)
; ==============================================================================
FlushMemory(*) {
    Log("[RAM] Flushing Working Sets...")
    ProcessList := ["RobloxPlayerBeta.exe", "Discord.exe", "Chrome.exe", "msedge.exe", "explorer.exe"]
    for procName in ProcessList {
        if PID := ProcessExist(procName) {
            hProcess := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", PID, "Ptr")
            if (hProcess) {
                DllCall("Psapi.dll\EmptyWorkingSet", "Ptr", hProcess)
                DllCall("CloseHandle", "Ptr", hProcess)
            }
        }
    }
    Log("[RAM] ✓ Memory flushed. Auto-flush armed (30s).")
    SetTimer(AutoFlushRoblox, 30000)
}

AutoFlushRoblox() {
    if (PID := ProcessExist("RobloxPlayerBeta.exe")) {
        h := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", PID, "Ptr")
        DllCall("Psapi.dll\EmptyWorkingSet", "Ptr", h)
        DllCall("CloseHandle", "Ptr", h)
    }
}

; ==============================================================================
; [GAME 1] ROBLOX FASTFLAGS (The Secret Sauce)
; ==============================================================================
InjectFastFlags(*) {
    Log("[Flags] Locating Roblox...")
    RobloxPath := EnvGet("LocalAppData") "\Roblox\Versions"
    TargetDir := ""
    
    try {
        Loop Files, RobloxPath "\*", "D" 
            if FileExist(A_LoopFilePath "\RobloxPlayerBeta.exe")
                TargetDir := A_LoopFilePath "\ClientSettings"
    }

    if (TargetDir = "") {
        Log("[Flags] ⚠ Roblox not found in standard path.")
        return
    }
    
    if !DirExist(TargetDir)
        DirCreate(TargetDir)

    ; ULTRA LOW GRAPHICS + FPS UNLOCK JSON
    SettingsJSON := '
    (
    {
        "DFIntTaskSchedulerTargetFps": 999,
        "FFlagDisablePostFx": true,
        "FFlagFastGPULightCulling": true,
        "FIntDebugForceMSAASamples": 0,
        "DFIntTextureCompositorActiveJobs": 0,
        "FFlagDebugGraphicsDisableShadows": true,
        "FFlagDebugGraphicsDisableCoarseShading": true,
        "FFlagDebugGraphicsDisableLightGrid": true
        "FFlagDebugGraphicsDisableDirect3D11": false,
        "FFlagDebugForceD3D11NoFeatureLevel11": true,
        "FFlagDebugGraphicsPreferD3D11": true,
        "FFlagD3D11UseEngineTextureAllocator": true,
        "DFFlagTextureQualityOverrideEnabled": true,
        "DFIntTextureQualityOverride": 0,
        "FIntTextureCompositorLowResFactor": 4,
        "DFFlagEnableRequestAsyncCompression": true,
        "FIntRomarkTextureQuality": 0,
        "FFlagBackgroundLoadTextures": true,
        "DFIntDebugFRMQualityLevelOverride": 1,
        "DFIntDebugRestrictGCDistance": 1,
        "DFFlagDebugRenderForceTechnologyVoxel": true,
        "FFlagDebugForceVoxelLighting": true,
        "FFlagDebugDisableDeferredShading": true,
        "FFlagDisableShadows": true,
        "FFlagDisableBloom": true,
        "FFlagDisableDepthOfField": true,
        "FFlagDisableGlobalShadows": true,
        "FFlagNewLightAttenuation": false,
        "FIntRenderShadowIntensity": 0,
        "FIntRenderLocalLightUpdatesMax": 0,
        "FIntRenderLocalLightUpdatesMin": 0,
        "FIntFRMMaxGrassDistance": 0,
        "FIntFRMMinGrassDistance": 0,
        "FFlagRenderGrassWithStandardMaterial": false,
        "DFIntCSGLevelOfDetailSwitchingDistance": 0,
        "FIntRenderMeshLodGroupScale": 0,
        "FFlagRenderPreCulledMeshes": true,
        "FFlagGlobalWindRendering": false,
        "FFlagGlobalWindActivated": false,
        "FIntRenderCloudPreCullingDistance": 0,
        "FFlagRenderCloudsAsMeshes": true,
        "FFlagDisableVolumetricClouds": false,
        "FFlagDisableAtmosphereEffects": true,
        "FFlagDebugDisableAntiAliasing": true,
        "DebugForceMSAASamples": 0,
        "FFlagAudioCompactorEnabled": true,
        "FIntAudioCompactorMaxBuffers": 4,
        "FFlagSoundServiceUseLowPriorityThreads": true,
        "FFlagDisableUiBlurEffects": true,
        "FFlagDisableCoreGuiAnimations": true,
        "FFlagKeepGuiLayoutClean": true,
        "FFlagPreloadImportantAssets": true,
        "FFlagFastCharacterLoad": true,
        "FFlagFastLoadAssets": true,
        "FFlagEnableFastAssetCaching": true,
        "DFIntAssetLoadTimeoutMillis": 5000,
        "FIntAssetCacheMaxItems": 1024,
        "FFlagPrioritizeLocalPlayerAssets": true,
        "FFlagEnableParallelAwake": true,
        "FFlagParallelHumanoidManager": true,
        "FFlagEnableParallelPhysics": true,
        "FFlagPrecomputeNavMesh": false,
        "FFlagDebugGcIsAggressive": true,
        "FIntGcForceStepMS": 2,
        "FIntFreeMemoryThresholdMB": 768,
        "FFlagEnableUnusedMemoryPurge": true,
        "FFlagLogToOutputWindow": false,
        "FFlagDebugDisableLocalLogging": true,
        "FFlagEnableReducedLatency": true,
        "FFlagGraphicsDynamicMaxFPS": true,
        "DFIntTaskSchedulerTargetFps": 60,
        "FFlagDisableTelemetryV2": true,
        "FFlagDebugDisableTelemetry": true,
        "FFlagTelemetryDisableAppStartV2": true,
        "FFlagTelemetryDisablePeriodicV2": true,
        "FFlagCRServerLogTelemetry": false,
    }
    )'
    
    FileOpen(TargetDir "\ClientAppSettings.json", "w").Write(SettingsJSON)
    Log("[Flags] ✓ Performance Flags injected successfully.")
}

; ==============================================================================
; [GAME 2] REGISTRY: GAME MODE + FULLSCREEN OPTS + GPU PRIORITY
; ==============================================================================
OptimizeGamingRegistry(*) {
    Log("[Reg] Applying Game Mode & Fullscreen optimizations...")
    try {
        ; 1. Enable Windows Game Mode
        RegWrite(1, "REG_DWORD", "HKCU\Software\Microsoft\GameBar", "AllowAutoGameMode")
        RegWrite(1, "REG_DWORD", "HKCU\Software\Microsoft\GameBar", "AutoGameModeEnabled")
        
        ; 2. Disable "Fullscreen Optimizations" (Fixes input lag/stutter)
        RegWrite(2, "REG_DWORD", "HKCU\System\GameConfigStore", "GameDVR_FseBehavior")
        RegWrite(0, "REG_DWORD", "HKCU\System\GameConfigStore", "GameDVR_Enabled")

        ; 3. Force High Performance GPU for Robl ox Use code with caution.
        ; Finds Roblox path and forces "High Performance" in Windows Graphics Settings

if (PID := ProcessExist("RobloxPlayerBeta.exe")) {
Path := ProcessGetPath(PID)

if (Path) {
; GpuPreference=2 means "High Performance"
RegWrite("GpuPreference=2;", "REG_SZ", "HKCU\Software\Microsoft\DirectX\UserGpuPreferences", Path)
Log("[Reg] ✓ GPU Preference set to HIGH for: " Path)
}
} else {
Log("[Reg] ⚠ Roblox not running - Skipping GPU Priority Tag.")
}
} 
catch as e 
{
Log("[Reg] ⚠ Registry Error: " e.Message)
}
Log("[Reg] ✓ Game Mode forced ON. Fullscreen Opts DISABLED.")
}
; ==============================================
; [NET] NETWORK THROTTLING & TCP
; ==============================================
OptimizeNetwork(*) {
Log("[Net] Optimizing Network Throttling...")
try 
{
; Disables Network Throttling Index (Default is 10, FFFFFFFF is disabled)RegWrite(0xFFFFFFFF, "REG_DWORD", "HKLM\SOF TWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "NetworkThrottlingIndex")RegWrite(0xFFFFFFFF, "REG_DWORD", "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile", "SystemResponsiveness")Log("[Net] ✓ Network Throttling Disabled.")
} catch {
Log("[Net] ⚠ Admin required for Network tweaks.")
}
}
; ========================================
; [DISPLAY] MAXIMIZE REFRESH RATE
;=========================================
MaximizeRefreshRate(*) {
Log("[Display] Checking for higher refresh rates...")

MaxRate := 60
CurrentRate := 0
}
; 1. Get Current Rate

try {
for obj in ComObjGet("winmgmts:").ExecQuery("SELECT CurrentRefreshRate FROM Win32_VideoController")
CurrentRate := obj.CurrentRefreshRate
}

; 2. Use ChangeDisplaySettings API to attempt switch
; (This is a simplified safety check - it won't force unsupported rates)

try {
DEVMODE := Buffer(156, 0)
NumPut("UShort", 156, DEVMODE, 36) ; dmSize

; Enumerating settings to find max supported frequency

Loop {
if !DllCall("EnumDisplaySettingsA", "Ptr", 0, "UInt", A_Index-1, "Ptr", DEVMODE)
breakThisRate := NumGet(DEVMODE, 120, "UInt") 

; dmDisplayFrequencyif (ThisRate > MaxRate)MaxRate := ThisRate}

if (MaxRate > CurrentRate) {
Log("[Display] Boosting Hz from " CurrentRate " to " MaxRate "...")

; We won't force the switch blindly via script as it can black-screen some monitors
; Instead we open the exact settings page for the user
; Function to get the current display device settings including maximum refresh rate

GetMaxRefreshRate() {
    ; Initialize DEVMODE structure
    VarSetCapacity(devmode, 220, 0) ; DEVMODE structure size
    NumPut(220, devmode, 36, "UShort") ; dmSize

    display := 0  ; primary display
    maxRate := 0

    ; Enumerate possible modes for the display
    i := 0
    while (DllCall("EnumDisplaySettingsW", "UInt", display, "UInt", i, "UInt", &devmode)) {
        rate := NumGet(devmode, 104, "UInt") ; dmDisplayFrequency at offset 104
        if (rate > maxRate) {
            maxRate := rate
        }
        i++
    }
    return maxRate
}

; Function to set display refresh rate
SetRefreshRate(rate) {
    VarSetCapacity(devmode, 220, 0)
    NumPut(220, devmode, 36, "UShort") ; dmSize

    ; Get current settings
    if !DllCall("EnumDisplaySettingsW", "UInt", 0, "UInt", -1, "UInt", &devmode)
        return false

    ; Set the new refresh rate
    NumPut(rate, devmode, 104, "UInt") ; dmDisplayFrequency at offset 104
    dmFields := 0x400000 ; DM_DISPLAYFREQUENCY
    res := DllCall("ChangeDisplaySettingsW", "UInt", &devmode, "UInt", 0)
    return res = 0 ; DISP_CHANGE_SUCCESSFUL = 0
}

; ---------------------- Main Script ----------------------

maxRate := GetMaxRefreshRate()
if (maxRate) {
    MsgBox("Maximum display refresh rate detected: " maxRate " Hz")
    if SetRefreshRate(maxRate)
        MsgBox("Refresh rate set to maximum: " maxRate " Hz")
    else
        MsgBox("Failed to set refresh rate.")
} else {
    MsgBox("Could not detect refresh rate.")
}Log("[Display] ⚠ Opening Display Settings. Select " MaxRate "Hz manually!")
} else {
Log("[Display] ✓ Already at Max Refresh Rate: " CurrentRate "Hz")
}
}
}

