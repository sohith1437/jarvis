@echo off
title J.A.R.V.I.S. Launcher
color 0B

echo ========================================================
echo               STARTING J.A.R.V.I.S. SYSTEM
echo ========================================================
echo.

cd /d "%~dp0"

:: 1. Ensure Ollama is running
echo [1/3] Checking Ollama server...
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I /N "ollama.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo Starting local Ollama server in background...
    start "" /B ollama serve
    timeout /t 2 >nul
) else (
    echo Ollama is already running.
)

:: 2. Launch Dashboard HUD
echo [2/3] Launching J.A.R.V.I.S. Dashboard HUD...
start "" ".\venv\Scripts\pythonw.exe" "dashboard\dashboard.py"

:: 3. Launch Main Voice Assistant Engine in this console
echo [3/3] Launching J.A.R.V.I.S. Voice Engine...
echo.
echo ========================================================
echo     Speak "Jarvis" to wake. Say "go to sleep" to rest.
echo ========================================================
echo.

".\venv\Scripts\python.exe" "main.py"

pause
