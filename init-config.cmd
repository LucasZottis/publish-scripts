@echo off
setlocal

REM Caminho do script PowerShell (mesma pasta do .cmd)
set SCRIPT_PATH=%~dp0init-config.ps1

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

endlocal
pause
