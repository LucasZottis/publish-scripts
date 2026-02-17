@echo off
echo Configurando PATH do Publicador...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts/setup.ps1"

echo.
echo Finalizado.
pause
