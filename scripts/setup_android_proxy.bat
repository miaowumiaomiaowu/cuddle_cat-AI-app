@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ------------------------------------------------------------
REM  setup_android_proxy.bat
REM  One-click helper to:
REM    - funnel Android emulator traffic through local Clash (HTTP/SOCKS 127.0.0.1:7890)
REM    - map backend service port 8002 to host via adb reverse (use http://127.0.0.1:8002)
REM ------------------------------------------------------------

REM Check adb availability
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] adb not found in PATH. Please install Android Platform Tools and add to PATH.
  echo Download: https://developer.android.com/studio/releases/platform-tools
  pause
  exit /b 1
)


REM Ensure adb server is running
adb start-server >nul 2>nul

REM Detect running device/emulator (robust parsing of adb devices)
set DEVICE_FOUND=
for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
  if "%%b"=="device" set DEVICE_FOUND=1
)
if not defined DEVICE_FOUND (
  echo [INFO] No device/emulator detected. Waiting for ADB to report a device...
  adb wait-for-device >nul 2>nul
  timeout /t 2 >nul 2>nul
  set DEVICE_FOUND=
  for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
    if "%%b"=="device" set DEVICE_FOUND=1
  )
)
if not defined DEVICE_FOUND (
  echo [INFO] Still no device. You can start an AVD from Android Studio ^(Device Manager^) or connect a device with USB debugging.
  echo [HINT] After the emulator boots, rerun this script.
  pause
  exit /b 1
)


REM Optional: show connected devices
adb devices

REM Remove existing reverse rules to avoid duplicates
adb reverse --remove-all >nul 2>nul

REM Create reverse mapping for backend service port 8002
adb reverse tcp:8002 tcp:8002
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Failed to map backend port 8002. Ensure device is authorized ^(check phone/emulator^) and try again.
  exit /b 1
)

REM Create reverse mapping for HTTP/HTTPS proxy (Clash default 7890)
adb reverse tcp:7890 tcp:7890
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Failed to map proxy port 7890. Ensure device is authorized ^(check phone/emulator^) and try again.
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
echo   1) Keep Clash for Windows running (system proxy ON is fine) ^(optional^)
echo   2) For backend, ensure your app base URL is http://127.0.0.1:8002 (.env SERVER_BASE_URL)
echo   3) If network fails after emulator reboot, rerun this script

echo Done.
endlocal
exit /b 0

