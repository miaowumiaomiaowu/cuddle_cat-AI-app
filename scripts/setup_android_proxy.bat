@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ------------------------------------------------------------
REM  setup_android_proxy.bat
REM  One-click helper to funnel Android emulator traffic through
REM  local Clash (HTTP/SOCKS on 127.0.0.1:7890) using adb reverse.
REM ------------------------------------------------------------

REM Check adb availability
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] adb not found in PATH. Please install Android Platform Tools and add to PATH.
  echo Download: https://developer.android.com/studio/releases/platform-tools
  pause
  exit /b 1
)

REM Detect running device/emulator
for /f "tokens=*" %%i in ('adb devices ^| findstr /R ".*\tdevice$"') do set DEVICE_FOUND=1
if not defined DEVICE_FOUND (
  echo [INFO] No device/emulator detected. Trying to start the default Android emulator...
  echo    - Please make sure an emulator is running, or connect a device with USB debugging.
  echo    - You can start an AVD from Android Studio > Device Manager.
  pause
  exit /b 1
)

REM Remove existing reverse rules to avoid duplicates
adb reverse --remove-all >nul 2>nul

REM Create reverse mapping for HTTP/HTTPS proxy (Clash default 7890)
adb reverse tcp:7890 tcp:7890
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Failed to create adb reverse mapping. Ensure device is authorized (check phone/emulator) and try again.
  exit /b 1
)

REM Optional: show current reverse list
for /f "tokens=*" %%i in ('adb reverse --list') do set HAS_REVERSE=1
if defined HAS_REVERSE (
  echo [OK] adb reverse rule created successfully:
  adb reverse --list
) else (
  echo [WARN] adb reverse rule may not be active. Please run again if network fails.
)

REM Quick connectivity hint
echo.
echo Next steps:
echo   1) Keep Clash for Windows running (system proxy ON is fine)
echo   2) Ensure your app uses proxy 127.0.0.1:7890 (already in .env)
echo   3) If network fails after emulator reboot, rerun this script

echo Done.
endlocal
exit /b 0

