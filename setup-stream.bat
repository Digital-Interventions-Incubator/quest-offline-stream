@echo off
setlocal
title Quest 3 Wireless Setup (one-time, per headset reboot)
echo ------------------------------------------------------
echo  QUEST 3 WIRELESS SETUP
echo  1. Connect the Quest to this PC with the USB-C cable.
echo  2. Put the headset on and accept "Always allow USB
echo     debugging from this computer" if it asks.
echo  3. Leave the cable plugged in until this script says so.
echo ------------------------------------------------------
pause

:: adb.exe ships inside the scrcpy zip. This bat must live in that folder.
if not exist "%~dp0adb.exe" (
    echo ERROR: adb.exe not found next to this script.
    echo Put this file inside your unzipped scrcpy folder ^(e.g. C:\scrcpy^).
    pause
    exit /b 1
)

"%~dp0adb.exe" get-state >nul 2>&1
if errorlevel 1 (
    echo ERROR: No headset detected over USB.
    echo Check the cable, then unlock the headset and accept the
    echo "USB debugging" dialog.
    pause
    exit /b 1
)

echo Switching the headset to wireless mode (port 5555)...
"%~dp0adb.exe" tcpip 5555

echo Detecting the Quest's Wi-Fi IP...
set "IP="
for /f "usebackq delims=" %%a in (`"%~dp0adb.exe" shell ip route ^| findstr "src" ^| powershell -NoProfile -Command "($input -join ' ') -replace '\r' -split '\s+' | Select-Object -Last 1"`) do set "IP=%%a"

if not defined IP (
    echo ERROR: Could not read the headset's Wi-Fi IP.
    echo Make sure the Quest is connected to Wi-Fi, then try again.
    pause
    exit /b 1
)

> "%~dp0quest-ip.txt" echo %IP%
echo Saved IP: %IP%
echo.
echo DONE. You can unplug the USB cable now.
echo From now on, double-click "queststream.bat" to stream wirelessly.
echo If it fails later, the headset IP may have changed: just run
echo this setup again.
pause
