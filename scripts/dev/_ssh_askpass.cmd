@echo off
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /B /C:"SERVER_PASS=" "%~dp0..\..\.env"`) do echo(%%B
