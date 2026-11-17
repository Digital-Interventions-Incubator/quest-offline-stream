@echo off
setlocal EnableDelayedExpansion
title Quest 3 Wireless Streamer

:: ---- Fine-tune knobs ----
:: Tilt correction in degrees (positive = clockwise). Try 0, 10, -10...
:: The right eye gets the OPPOSITE tilt (mirrored stereo half).
set "TILT_L=22"
:: Manual crop overrides as "W:H:X:Y" in mirror-surface pixels (3200x1728).
:: Leave empty to auto-compute (left: x=0, right: x=1600). Example:
:: set "MANUAL_CROP_R=1560:877:1640:425"
set "MANUAL_CROP_L="
set "MANUAL_CROP_R="

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
:: Mirror-surface size override (Quest 3: confirmed via scrcpy "Texture: WxH"
:: log line — the mirrored surface equals the panel, 4128x2208).
:: Empty these two to fall back to `wm size` detection.
set "NATIVE_W=4128"
set "NATIVE_H=2208"
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
:: h264 needs even dimensions; round down.
set /a CH=CH/2*2, CY=CY/2*2
if %EYE%==1 (
    set "TILT_ARGS=--angle=%TILT_L% --fullscreen"
) else (
    set /a TILT_R=0-TILT_L
    set "TILT_ARGS=--angle=!TILT_R! --fullscreen"
)
if %EYE%==1 (
    if defined MANUAL_CROP_L (set "CROP=--crop=%MANUAL_CROP_L%") else set "CROP=--crop=%HALF%:%CH%:0:%CY%"
) else (
    if defined MANUAL_CROP_R (set "CROP=--crop=%MANUAL_CROP_R%") else set "CROP=--crop=%HALF%:%CH%:%HALF%:%CY%"
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
