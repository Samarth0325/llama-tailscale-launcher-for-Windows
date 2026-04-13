::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFChVQQWQKGP6IrAP4OXu5OKCnmkYR+krd5/nzrWHLPMQ60nhOIIi0X1WnYUJFB44
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
set LOG=C:\llama_launcher.log
@echo off
setlocal

echo ===============================
echo   SMART LAUNCHER
echo ===============================

:: ===== CONFIG =====
set LLAMA_DIR=C:\llama.cpp
set MODEL_PATH=%LLAMA_DIR%\models\qwen2.5-0.5b-instruct-q4_k_m_Samarth_Deshmukhe.gguf

:: ===== AUTO ADMIN ELEVATION =====
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

:: ===== QUICK CHECK =====
set READY=1

where tailscale >nul 2>&1 || set READY=0
where git >nul 2>&1 || set READY=0
where cmake >nul 2>&1 || set READY=0
if not exist %LLAMA_DIR%\build\bin\Release\llama-server.exe set READY=0
if not exist %MODEL_PATH% set READY=0

:: ===== FAST MODE =====
if "%READY%"=="1" (
    echo [FAST MODE] Everything already installed
    goto RUN
)

:: ===== SETUP MODE =====
echo [SETUP MODE] Installing missing components...

:: --- TAILSCALE ---
where tailscale >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Tailscale...
    powershell -Command "Invoke-WebRequest https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -OutFile tailscale.exe"
    start /wait tailscale.exe
)

:: --- GIT ---
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Git...
    powershell -Command "Invoke-WebRequest https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe -OutFile git.exe"
    start /wait git.exe
)

:: --- CMAKE ---
where cmake >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing CMake...
    powershell -Command "Invoke-WebRequest https://github.com/Kitware/CMake/releases/latest/download/cmake-3.29.0-windows-x86_64.msi -OutFile cmake.msi"
    start /wait cmake.msi
)

:: --- LLAMA.CPP ---
if not exist %LLAMA_DIR% (
    echo Cloning llama.cpp...
    git clone https://github.com/ggml-org/llama.cpp %LLAMA_DIR%
)

:: --- BUILD LLAMA (IMPORTANT) ---
if not exist %LLAMA_DIR%\build (
    echo Building llama.cpp...
    cd /d %LLAMA_DIR%
    cmake -B build
    cmake --build build --config Release
)

:: --- MODEL ---
if not exist %LLAMA_DIR%\models mkdir %LLAMA_DIR%\models

if not exist %MODEL_PATH% (
    echo Downloading model...
    powershell -Command Invoke-WebRequest -Uri "https://huggingface.co/bartowski/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-Q4_K_M_.gguf" -OutFile "models\qwen2.5-0.5b-instruct-q4_k_m.gguf"


)

:: ===== RUN MODE =====
:RUN

echo.
echo ===============================
echo   TOGGLE CHECK
echo ===============================

:: Check Tailscale status
tailscale status >nul 2>&1

IF %ERRORLEVEL%==0 (
    echo.
    echo ===============================
    echo   STOPPING SERVICES
    echo ===============================

    echo [INFO] Stopping LLaMA server...
    taskkill /f /im llama-server.exe /t >nul 2>&1

    echo [INFO] Disconnecting Tailscale...
    tailscale down

    echo.
    echo [DONE] Everything stopped
    pause
    exit /b
)

:: ===== START MODE =====
echo.
echo ===============================
echo   STARTING SERVICES
echo ===============================

:: Start Tailscale
net start Tailscale >nul 2>&1
tailscale up --accept-dns --accept-routes --login-server=https://ai.nomineelife.com:8443 >nul 2>&1

timeout /t 5 >nul

:: Free port 8080
taskkill /im tnslsnr.exe /f >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: Start server
echo Starting LLaMA server...

cd /d %LLAMA_DIR%

start "" "%LLAMA_DIR%\build\bin\Release\llama-server.exe" -m "%MODEL_PATH%" --host 0.0.0.0 --port 8080


:: Open panel
echo Opening panel...
start "" "https://ai.nomineelife.com/"

echo.
echo ===============================
echo   DONE
echo ===============================
echo.

exit