@echo off
rem EMG@NJU Website Content Manager
cd /d "%~dp0"
rem Add git to PATH for the "push to GitHub" feature
set "PATH=C:\Users\zhouy\.workbuddy\binaries\PortableGit\versions\1.2.0\mingw64\bin;%PATH%"
"C:\Users\zhouy\.workbuddy\binaries\python\envs\default\Scripts\python.exe" "%~dp0admin\server.py"
pause
