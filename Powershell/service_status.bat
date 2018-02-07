@echo off
set service=%1

for /F "tokens=3 delims=: " %%H in ('sc query %service% ^| findstr "STATE"') do (
	if /I "%%H" EQU "RUNNING" (
		echo RUNNING
	)
)