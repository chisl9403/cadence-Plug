@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ═══════════════════════════════════════════════════════════════════
:: Cadence Capture SVN Plugin - Standalone Uninstaller
:: Version: 1.0 | Date: 2025-12-04
:: 
:: This is a standalone uninstaller.
:: Can be run from any location.
:: ═══════════════════════════════════════════════════════════════════

cls
color 0C
echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║   Cadence Capture SVN Plugin - Uninstaller                ║
echo ║   Version: 1.0 ^| Date: 2025-12-04                          ║
echo ║                                                            ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo This will REMOVE the SVN Plugin from Cadence Capture.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

cls
echo.
echo ════════════════════════════════════════════════════════════
echo   Uninstallation Progress
echo ════════════════════════════════════════════════════════════
echo.

:: ═══════════════════════════════════════════════════════════════════
:: STEP 1: Auto-detect Cadence installation
:: ═══════════════════════════════════════════════════════════════════
echo [1/3] Detecting Cadence Capture installation...

set "CAPTURE_DIR="
set "DETECTED=0"

:: Check common installation paths
for %%d in (
    "C:\Cadence\Cadence_SPB_17.2-2016\tools\capture"
    "C:\Cadence\SPB_17.2\tools\capture"
    "D:\Cadence\Cadence_SPB_17.2-2016\tools\capture"
    "D:\Cadence\SPB_17.2\tools\capture"
    "E:\Cadence\Cadence_SPB_17.2-2016\tools\capture"
) do (
    if exist "%%~d\tclscripts" (
        set "CAPTURE_DIR=%%~d"
        set "DETECTED=1"
        goto :found_cadence
    )
)

:not_found_cadence
echo.
echo       [WARNING] Automatic detection failed
echo.
echo ┌───────────────────────────────────────────────────────────┐
echo │ Please enter your Cadence Capture installation path:      │
echo │                                                            │
echo │ Example:                                                   │
echo │   C:\Cadence\Cadence_SPB_17.2-2016\tools\capture          │
echo │                                                            │
echo └───────────────────────────────────────────────────────────┘
echo.
set /p CAPTURE_DIR="Capture path: "

:: Validate user input
if not exist "%CAPTURE_DIR%\tclscripts" (
    echo.
    echo [ERROR] Invalid path. Directory structure not recognized.
    goto :error_exit
)

:found_cadence
if "%DETECTED%"=="1" (
    echo       ^> Auto-detected: %CAPTURE_DIR%
) else (
    echo       ^> User provided: %CAPTURE_DIR%
)
echo.

:: ═══════════════════════════════════════════════════════════════════
:: STEP 2: Check for installed files
:: ═══════════════════════════════════════════════════════════════════
echo [2/3] Checking for installed files...

set "MENU_FILE=%CAPTURE_DIR%\menu\CaptureMenuPlugin.men"
set "TCL_FILE=%CAPTURE_DIR%\tclscripts\capAutoLoad\CaptureMenuPlugin.tcl"
set "FILES_FOUND=0"

if exist "%MENU_FILE%" (
    echo       ^> Found: menu\CaptureMenuPlugin.men
    set "FILES_FOUND=1"
)

if exist "%TCL_FILE%" (
    echo       ^> Found: tclscripts\capAutoLoad\CaptureMenuPlugin.tcl
    set "FILES_FOUND=1"
)

if "%FILES_FOUND%"=="0" (
    echo       ^> No plugin files found
    echo.
    echo ════════════════════════════════════════════════════════════
    echo   Plugin is not installed or already removed.
    echo ════════════════════════════════════════════════════════════
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 0
)
echo.

:: ═══════════════════════════════════════════════════════════════════
:: STEP 3: Remove files
:: ═══════════════════════════════════════════════════════════════════
echo [3/3] Removing plugin files...

set "REMOVED=0"

if exist "%MENU_FILE%" (
    del /F /Q "%MENU_FILE%" 2>nul
    if not exist "%MENU_FILE%" (
        echo       ^> Removed: menu\CaptureMenuPlugin.men
        set "REMOVED=1"
    ) else (
        echo       [ERROR] Cannot delete: %MENU_FILE%
        echo              Check if Cadence Capture is running
    )
)

if exist "%TCL_FILE%" (
    del /F /Q "%TCL_FILE%" 2>nul
    if not exist "%TCL_FILE%" (
        echo       ^> Removed: tclscripts\capAutoLoad\CaptureMenuPlugin.tcl
        set "REMOVED=1"
    ) else (
        echo       [ERROR] Cannot delete: %TCL_FILE%
        echo              Check if Cadence Capture is running
    )
)

if "%REMOVED%"=="0" (
    goto :error_exit
)

echo.

:: ═══════════════════════════════════════════════════════════════════
:: SUCCESS
:: ═══════════════════════════════════════════════════════════════════
color 0A
cls
echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║           ✓ Uninstallation Successful!                    ║
echo ║                                                            ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo ════════════════════════════════════════════════════════════
echo   Uninstallation Summary
echo ════════════════════════════════════════════════════════════
echo.
echo   Removed from:
echo     %CAPTURE_DIR%
echo.
echo   The SVN Plugin has been completely removed.
echo.
echo   Note:
echo     • Configuration files in project directories are preserved
echo       (.capture_svn_config, capture_svn_plugin.log)
echo     • You can safely delete them manually if needed
echo.
echo ════════════════════════════════════════════════════════════
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:: ═══════════════════════════════════════════════════════════════════
:: ERROR HANDLER
:: ═══════════════════════════════════════════════════════════════════

:error_exit
color 0C
echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║           ✗ Uninstallation Failed                         ║
echo ║                                                            ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo Please check:
echo   1. You have write permissions to Cadence directory
echo   2. Cadence Capture is not currently running
echo   3. Files are not locked by other programs
echo.
echo You can try:
echo   1. Close Cadence Capture
echo   2. Run this uninstaller as Administrator
echo   3. Delete files manually from:
echo      %CAPTURE_DIR%\menu\
echo      %CAPTURE_DIR%\tclscripts\capAutoLoad\
echo.
echo Press any key to exit...
pause >nul
exit /b 1
