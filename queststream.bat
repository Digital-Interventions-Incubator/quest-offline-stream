@echo off
setlocal
title Quest 3 Wireless Streamer + OBS
echo ------------------------------------------------------
echo  QUEST 3 WIRELESS STREAMER
echo ------------------------------------------------------

if not exist "%~dp0scrcpy.exe" (
    echo ERROR: scrcpy.exe not found next to this script.
    echo Put this file inside your unzipped scrcpy folder ^(e.g. C:\scrcpy^).
    pause
    exit /b 1
)
if not exist "%~dp0adb.exe" (
    echo ERROR: adb.exe not found next to this script.
    echo Put this file inside your unzipped scrcpy folder.
    pause
    exit /b 1
)

:: IP: first argument wins, otherwise the IP saved by setup-stream.bat
set "IP=%~1"
if not defined IP (
    if exist "%~dp0quest-ip.txt" (
        for /f "usebackq delims=" %%a in (`type "%~dp0quest-ip.txt"`) do (
            if not defined IP set "IP=%%a"
        )
    )
)
if not defined IP (
    echo ERROR: No headset IP saved yet.
    echo Plug the Quest in via USB and run "setup-stream.bat" once,
    echo or run: queststream.bat 192.168.x.x
    pause
    exit /b 1
)

echo 1. Connecting to the Quest at %IP%:5555 ...
"%~dp0adb.exe" connect %IP%:5555 | findstr /c:"connected to" >nul
if errorlevel 1 (
    echo ERROR: Could not connect.
    echo  - Is the headset awake and on the same Wi-Fi as this PC?
    echo  - Did you run "setup-stream.bat" after the last headset reboot?
    echo  - IP changed? Run setup-stream.bat again.
    pause
    exit /b 1
)

echo 2. Launching OBS Studio...
if exist "C:\Users\Public\Desktop\OBS Studio.lnk" (
    start "" "C:\Users\Public\Desktop\OBS Studio.lnk"
) else if exist "%ProgramFiles%\obs-studio\bin\64bit\obs64.exe" (
    start "" "%ProgramFiles%\obs-studio\bin\64bit\obs64.exe"
) else (
    echo   OBS not found - skipping. Start it manually if needed.
)

echo 3. Launching scrcpy (window: Quest3Full)...
"%~dp0scrcpy.exe" --window-title "Quest3Full" --video-codec=h264 --video-bit-rate=12M --max-fps=60 -m 1600 --video-buffer=5 --no-audio

echo ------------------------------------------------------
echo  Stream closed.
pause
