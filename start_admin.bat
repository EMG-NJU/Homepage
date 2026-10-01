@echo off
setlocal EnableExtensions EnableDelayedExpansion
title EMG@NJU Website Content Manager
cd /d "%~dp0"

rem ===================================================================
rem  EMG@NJU 网站内容管理工具 - 通用启动器 v4
rem -------------------------------------------------------------------
rem  自动检测本机 Python 3 和 Git，不写死任何用户名或绝对路径，
rem  所以在任何一台装有 Python 3 的 Windows 电脑上都能直接双击运行。
rem ===================================================================

set "PF86=%ProgramFiles(x86)%"
set "LOG=%~dp0_launcher_diagnostics.txt"
set "PYRUN="
set "PYPATH="
set "GITDIR="

>"%LOG%" echo EMG@NJU launcher diagnostics
>>"%LOG%" echo time        : %DATE% %TIME%
>>"%LOG%" echo script dir  : %~dp0
>>"%LOG%" echo userprofile : %USERPROFILE%
>>"%LOG%" echo.
>>"%LOG%" echo --- Python candidates ---

rem ---------- 1. 定位 Git（只有“推送到 GitHub”需要用到） --------------
for /f "delims=" %%G in ('where git 2^>nul') do (
    if not defined GITDIR set "GITDIR=%%~dpG"
)
if not defined GITDIR (
    for /d %%D in ("%USERPROFILE%\.workbuddy\binaries\PortableGit\versions\*") do (
        if not defined GITDIR if exist "%%~fD\mingw64\bin\git.exe" set "GITDIR=%%~fD\mingw64\bin"
    )
)
if defined GITDIR set "PATH=!GITDIR!;!PATH!"

rem ---------- 2. 定位 Python 3 ----------------------------------------
rem 2.1 随工具自带的便携版 Python（如果以后放进来了就优先用它）
call :try "%~dp0python\python.exe"
call :try "%~dp0admin\python\python.exe"
call :try "%~dp0.venv\Scripts\python.exe"

rem 2.2 系统正式安装的 Python（python.org / Microsoft Store 之外）
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do call :try "%%~fD\python.exe"
for /d %%D in ("%ProgramFiles%\Python3*") do call :try "%%~fD\python.exe"
for /d %%D in ("%PF86%\Python3*") do call :try "%%~fD\python.exe"
for /d %%D in ("C:\Python3*") do call :try "%%~fD\python.exe"
call :try "%LOCALAPPDATA%\Programs\Python\Launcher\py.exe"

rem 2.3 Anaconda / Miniconda
call :try "%USERPROFILE%\anaconda3\python.exe"
call :try "%USERPROFILE%\miniconda3\python.exe"
call :try "%LOCALAPPDATA%\anaconda3\python.exe"
call :try "%LOCALAPPDATA%\miniconda3\python.exe"
call :try "%ProgramData%\anaconda3\python.exe"

rem 2.4 WorkBuddy 托管的 Python（版本目录 / 虚拟环境）
for /d %%D in ("%USERPROFILE%\.workbuddy\binaries\python\versions\*") do call :try "%%~fD\python.exe"
for /d %%D in ("%USERPROFILE%\.workbuddy\binaries\python\envs\*") do call :try "%%~fD\Scripts\python.exe"

rem 2.5 已经在 PATH 上的 python / python3（过滤掉微软商店的占位程序）
if not defined PYRUN (
    for /f "delims=" %%P in ('where python 2^>nul ^| find /i /v "WindowsApps"') do call :try "%%~fP"
)
if not defined PYRUN (
    for /f "delims=" %%P in ('where python3 2^>nul ^| find /i /v "WindowsApps"') do call :try "%%~fP"
)

rem 2.6 官方 py 启动器
if not defined PYRUN (
    py -3 -c "import sys" >nul 2>nul
    if not errorlevel 1 (
        set "PYRUN=py -3"
        set "PYPATH=py launcher (py -3)"
        >>"%LOG%" echo [ok  ] py -3
    )
)

if not defined PYRUN goto nopython

if not exist "%~dp0admin\server.py" goto noserver

echo  ---------------------------------------------------------------
echo   EMG@NJU 网站内容管理工具
echo   Python : !PYPATH!
if defined GITDIR (echo   Git    : !GITDIR!) else (echo   Git    : 未找到 - 站内“推送 GitHub”不可用)
echo  ---------------------------------------------------------------
echo   管理界面会自动在浏览器中打开：
echo   http://127.0.0.1:8765/
echo.
echo   编辑网站期间请保持本窗口开启，关闭窗口即停止管理服务。
echo  ---------------------------------------------------------------
echo.

%PYRUN% "%~dp0admin\server.py"
set "RC=!errorlevel!"

echo.
if not "!RC!"=="0" (
    echo  [错误] 管理服务异常退出，返回码 !RC!
    echo         详细检测记录：%LOG%
)
echo  管理服务已停止。
echo.
pause
exit /b !RC!


rem ===================================================================
rem  错误处理
rem ===================================================================
:nopython
echo.
echo  ===============================================================
echo   [错误] 这台电脑上没有找到 Python 3
echo  ===============================================================
echo.
echo   本管理工具需要用 Python 3 运行。请任选一种方式安装：
echo.
echo     方式一（推荐，命令行一条命令）：
echo         winget install -e --id Python.Python.3.12
echo.
echo     方式二（手动下载）：
echo         https://www.python.org/downloads/windows/
echo         安装时务必勾选 "Add python.exe to PATH"
echo.
echo   安装完成后关闭本窗口，重新双击 start_admin.bat 即可。
echo.
echo   详细的检测记录已保存到：
echo   %LOG%
echo.
choice /c 12 /n /m "  按 1 打开 Python 下载页面，按 2 退出 : "
if errorlevel 2 goto np_end
start "" "https://www.python.org/downloads/windows/"
:np_end
echo.
pause
exit /b 1

:noserver
echo.
echo  ===============================================================
echo   [错误] 找不到 admin\server.py
echo  ===============================================================
echo.
echo   start_admin.bat 必须和 admin 文件夹放在同一个目录里。
echo   当前目录：%~dp0
echo.
pause
exit /b 1


rem ===================================================================
rem  子过程：测试一个候选解释器，第一个可用的胜出
rem ===================================================================
:try
if defined PYRUN goto :eof
if not exist "%~1" (
    >>"%LOG%" echo [miss] %~1
    goto :eof
)
"%~1" -c "import sys" >nul 2>nul
if errorlevel 1 (
    >>"%LOG%" echo [bad ] %~1
    goto :eof
)
set PYRUN="%~1"
set "PYPATH=%~1"
>>"%LOG%" echo [ok  ] %~1
goto :eof
