@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ====================================
echo Cadence Capture SVN Plugin Uninstaller
echo ====================================
echo.

:: 自动检测 Cadence 安装路径
set "CAPTURE_DIR="

for %%d in (
    "C:\Cadence\Cadence_SPB_17.2-2016\tools\capture"
    "C:\Cadence\SPB_17.2\tools\capture"
    "D:\Cadence\Cadence_SPB_17.2-2016\tools\capture"
    "D:\Cadence\SPB_17.2\tools\capture"
) do (
    if exist "%%~d" (
        set "CAPTURE_DIR=%%~d"
        goto :found
    )
)

:not_found
echo [ERROR] Cadence Capture installation not found!
echo.
set /p CAPTURE_DIR="Enter Capture path (e.g., C:\Cadence\...\tools\capture): "

if not exist "%CAPTURE_DIR%" (
    echo [ERROR] Invalid path
    pause
    exit /b 1
)

:found
echo [OK] Found: %CAPTURE_DIR%
echo.
echo Removing installed files...
echo.

:: 删除 TCL 脚本
set "TCL_FILE=%CAPTURE_DIR%\tclscripts\capAutoLoad\CaptureMenuPlugin.tcl"
if exist "%TCL_FILE%" (
    del /F /Q "%TCL_FILE%"
    echo [OK] Removed: CaptureMenuPlugin.tcl
) else (
    echo [ - ] Not found: CaptureMenuPlugin.tcl
)

:: 删除菜单文件
set "MENU_FILE=%CAPTURE_DIR%\menu\CaptureMenuPlugin.men"
if exist "%MENU_FILE%" (
    del /F /Q "%MENU_FILE%"
    echo [OK] Removed: CaptureMenuPlugin.men
) else (
    echo [ - ] Not found: CaptureMenuPlugin.men
)

echo.
echo ====================================
echo Uninstallation Complete!
echo ====================================
echo.
echo Plugin has been removed from Capture.
echo.
