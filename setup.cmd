@echo off
echo Configurando PATH do Publicador...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-path.ps1"

echo.
echo Finalizado.
pause
