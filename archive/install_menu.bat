@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ====================================
echo Cadence Capture SVN Plugin Installer
echo ====================================
echo.

:: 设置项目目录
set "PROJECT_DIR=%~dp0"

:: 自动检测 Cadence 安装路径
set "CADENCE_DIR="
set "CAPTURE_DIR="

:: 检测常见安装路径
for %%d in (
    "C:\Cadence\Cadence_SPB_17.2-2016"
    "C:\Cadence\SPB_17.2"
    "D:\Cadence\Cadence_SPB_17.2-2016"
    "D:\Cadence\SPB_17.2"
) do (
    if exist "%%~d\tools\capture" (
        set "CADENCE_DIR=%%~d"
        set "CAPTURE_DIR=%%~d\tools\capture"
        goto :found
    )
)

:not_found
echo [ERROR] Cadence Capture installation not found!
echo.
echo Please enter your Cadence installation path:
echo Example: C:\Cadence\Cadence_SPB_17.2-2016
echo.
set /p CADENCE_DIR="Enter path: "
set "CAPTURE_DIR=%CADENCE_DIR%\tools\capture"

if not exist "%CAPTURE_DIR%" (
    echo [ERROR] Invalid path: %CAPTURE_DIR%
    echo.
    pause
    exit /b 1
)

:found
echo [OK] Found Capture: %CAPTURE_DIR%
echo.

:: 安装菜单文件
echo [Step 1/2] Installing menu file...
set "MENU_DIR=%CAPTURE_DIR%\menu"
if not exist "%MENU_DIR%" mkdir "%MENU_DIR%"

copy /Y "%PROJECT_DIR%CaptureMenuPlugin.men" "%MENU_DIR%\" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy menu file
    pause
    exit /b 1
)
echo [OK] CaptureMenuPlugin.men

:: 安装 TCL 脚本
echo.
echo [Step 2/2] Installing TCL script...
set "TCL_DIR=%CAPTURE_DIR%\tclscripts\capAutoLoad"
if not exist "%TCL_DIR%" mkdir "%TCL_DIR%"

copy /Y "%PROJECT_DIR%CaptureMenuPlugin.tcl" "%TCL_DIR%\" >nul
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy TCL script
    pause
    exit /b 1
)
echo [OK] CaptureMenuPlugin.tcl

echo.
echo ====================================
echo Installation Complete!
echo ====================================
echo.
echo Installed files:
echo   Menu:   %MENU_DIR%\CaptureMenuPlugin.men
echo   Script: %TCL_DIR%\CaptureMenuPlugin.tcl
echo.
echo Next steps:
echo   1. Start Cadence Capture
echo   2. Toolbar will auto-show (if enabled)
echo   3. Or use: Tools ^> SVN Tools ^> Show Toolbar
echo.
