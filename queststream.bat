@echo off
setlocal EnableDelayedExpansion
title Quest 3 Wireless Streamer

:: ---- Fine-tune knobs ----
:: Tilt correction in degrees (positive = clockwise). Try 0, 10, -10...
set "TILT=22"
:: Manual crop override as "W:H:X:Y" in mirror-surface pixels (3200x1728).
:: Leave empty to auto-compute. Example: set "MANUAL_CROP=1600:900:0:414"
set "MANUAL_CROP="

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
        for /f "usebackq delims=" %%a in ("%~dp0quest-ip.txt") do (
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

echo 2. Choose the view: L = left eye (normal screen), R = right eye, B = both eyes.
choice /c LRB /n /m "Your choice [L/R/B]: "
set "EYE=%errorlevel%"

set "CROP="
if %EYE%==3 goto launch

:: Read the headset's screen size to compute the crop.
set "W="
:: Mirror-surface size override (Quest 3: derived from scrcpy "Texture: WxH"
:: log line; the panel size from `wm size` is NOT the mirrored surface).
:: Empty these two to fall back to `wm size` detection.
set "NATIVE_W=3200"
set "NATIVE_H=1728"
if defined NATIVE_W set /a W=NATIVE_W, H=NATIVE_H 2>nul
if not defined W goto read_wm
goto have_size

:read_wm
"%~dp0adb.exe" -s %IP%:5555 shell wm size > "%~dp0wm.tmp" 2>nul
set "SIZE="
for /f "tokens=2,3" %%a in (%~dp0wm.tmp) do if /i "%%a"=="size:" set "SIZE=%%b"
del "%~dp0wm.tmp" >nul 2>&1
if not defined SIZE goto both_fallback
for /f "tokens=1,2 delims=x" %%i in ("%SIZE%") do set /a W=%%i, H=%%j 2>nul
if not defined H goto both_fallback

:have_size
:: Work in landscape: W = long side.
if %H% gtr %W% set /a W=W+H & set /a H=W-H & set /a W=W-H
set /a HALF=W/2, CH=HALF*9/16, CY=(H-CH)/2
set "TILT_ARGS=--angle=%TILT% --fullscreen"
if defined MANUAL_CROP (
    set "CROP=--crop=%MANUAL_CROP%"
) else if %EYE%==1 (
    set "CROP=--crop=%HALF%:%CH%:0:%CY%"
) else (
    set "CROP=--crop=%HALF%:%CH%:%HALF%:%CY%"
)
echo   Crop: %CROP%  (if the view looks wrong, report these numbers)
goto launch

:both_fallback
echo   Could not read the screen size - streaming both eyes instead.

:launch
echo 3. Launching scrcpy (window: Quest3Full)...
"%~dp0scrcpy.exe" --serial %IP%:5555 --window-title "Quest3Full" --video-codec=h264 --video-bit-rate=12M --max-fps=60 -m 1600 --video-buffer=5 --no-audio !CROP! !TILT_ARGS!

echo ------------------------------------------------------
echo  Stream closed.
pause
