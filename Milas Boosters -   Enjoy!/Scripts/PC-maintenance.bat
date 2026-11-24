@echo off
title JACS Maintenance Toolkit
>nul 2>&1 net session

echo JACS Maintenance Toolkit - running your chosen fixes
echo.
echo [1/20] Unlock the hidden 'Ultimate Performance' plan
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
echo.
echo [2/20] Rebuild the icon cache
ie4uinit.exe -show & taskkill /IM explorer.exe /F & del /A /Q "%localappdata%\IconCache.db" & start explorer.exe
echo.
echo [3/20] Refresh your internet connection
ipconfig /release && ipconfig /renew && ipconfig /flushdns
echo.
echo [4/20] Repair network settings (Winsock reset)
netsh winsock reset && netsh int ip reset
echo.
echo [5/20] Let Windows find the problem
msdt.exe /id NetworkDiagnosticsNetworkAdapter
echo.
echo [6/20] Use faster, reliable DNS (Google)
netsh interface ip set dns name="Wi-Fi" static 8.8.8.8 && netsh interface ip add dns name="Wi-Fi" 8.8.4.4 index=2
echo.
echo [7/20] Reset TCP auto-tuning to normal
netsh int tcp set global autotuninglevel=normal
echo.
echo [8/20] Restart the Windows desktop (Explorer)
taskkill /f /im explorer.exe & start explorer.exe
echo.
echo [9/20] Repair all built-in Windows apps
Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
echo.
echo [10/20] Repair damaged system files (SFC)
sfc /scannow
echo.
echo [11/20] Quickly check Windows health (DISM)
DISM /Online /Cleanup-Image /CheckHealth
echo.
echo [12/20] Deep-repair Windows (DISM RestoreHealth)
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo [13/20] Scan and fix disk errors on the fly
chkdsk C: /scan /forceofflinefix /perf
echo.
echo [14/20] Full disk repair (on next restart)
chkdsk C: /f /r /x
echo.
echo [15/20] Check if the disk is marked 'dirty'
fsutil dirty query C:
echo.
echo [16/20] Start a self-healing disk repair (fsutil)
fsutil repair initiate C:
echo.
echo [17/20] Optimise your drives
defrag C: /O
echo.
echo [18/20] Empty the Recycle Bin (all drives)
Clear-RecycleBin -Force
echo.
echo [19/20] Pause noisy background helpers
net stop "SysMain" & net stop "wuauserv"
echo.
echo [20/20] Refresh your connection for lower ping
ipconfig /flushdns && netsh interface tcp set global autotuninglevel=normal
echo.
echo All done! Your PC has had its tune-up.
pause
