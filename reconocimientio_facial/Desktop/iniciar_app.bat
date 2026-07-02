@echo off
chcp 65001 >nul
cd /d "%~dp0"
if exist .env.local (
  for /f "usebackq tokens=1,2 delims==" %%A in (".env.local") do set %%A=%%B
)
.venv\Scripts\python.exe app_desktop.py
pause
