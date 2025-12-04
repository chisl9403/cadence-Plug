@echo off
setlocal enabledelayedexpansion

:: ======================================================================================================================================================?
:: Cadence Capture SVN Plugin - Standalone Installer
:: Version: 1.0 | Date: 2025-12-04
:: 
:: This is a self-contained installer with embedded files.
:: Can be run from any location.
:: ======================================================================================================================================================?

:start_menu
cls
color 0A
echo.
echo ============================================================
echo.
echo    Cadence Capture SVN Plugin - Setup Program
echo    Version: 1.0 - Date: 2025-12-04
echo.
echo ============================================================
echo.
echo Please select an option:
echo.
echo   [1] Install Plugin
echo   [2] Uninstall Plugin
echo   [3] Exit
echo.
set /p "CHOICE=Enter your choice (1-3): "

if "%CHOICE%"=="1" goto :install
if "%CHOICE%"=="2" goto :uninstall
if "%CHOICE%"=="3" exit /b 0
echo.
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto :start_menu

:install
cls
echo.
echo =======================================================================================================================================
echo   Installation Mode
echo =======================================================================================================================================
echo.
echo This installer will:
echo   1. Auto-detect Cadence Capture installation
echo   2. Extract and install plugin files
echo   3. Configure auto-load settings
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

cls
echo.
echo =======================================================================================================================================
echo   Installation Progress
echo =======================================================================================================================================
echo.

:: ======================================================================================================================================================?
:: STEP 1: Create temporary extraction directory
:: ======================================================================================================================================================?
echo [1/5] Creating temporary directory...

set "TEMP_DIR=%TEMP%\CadenceSVN_%RANDOM%_%TIME:~-2%"
mkdir "%TEMP_DIR%" 2>nul

if not exist "%TEMP_DIR%" (
    echo [ERROR] Failed to create temporary directory
    goto :error_exit
)
echo       ^> OK: %TEMP_DIR%
echo.

:: ======================================================================================================================================================?
:: STEP 2: Extract embedded files
:: ======================================================================================================================================================?
echo [2/5] Extracting embedded files...

:: Extract TCL script
(findstr /B /C:"::TCL::" "%~f0") > "%TEMP_DIR%\raw_tcl.tmp"
powershell -NoProfile -Command "$content = (Get-Content '%TEMP_DIR%\raw_tcl.tmp' -Raw) -replace '(?m)^::TCL::', ''; $utf8 = New-Object System.Text.UTF8Encoding $false; [System.IO.File]::WriteAllText('%TEMP_DIR%\CaptureMenuPlugin.tcl', $content, $utf8)" 2>nul
del "%TEMP_DIR%\raw_tcl.tmp" 2>nul

if not exist "%TEMP_DIR%\CaptureMenuPlugin.tcl" (
    echo [ERROR] Failed to extract TCL script
    goto :cleanup_error
)
echo       ^> OK: CaptureMenuPlugin.tcl

:: Extract MEN file
(findstr /B /C:"::MEN::" "%~f0") > "%TEMP_DIR%\raw_men.tmp"
powershell -NoProfile -Command "$content = (Get-Content '%TEMP_DIR%\raw_men.tmp' -Raw) -replace '(?m)^::MEN::', ''; $utf8 = New-Object System.Text.UTF8Encoding $false; [System.IO.File]::WriteAllText('%TEMP_DIR%\CaptureMenuPlugin.men', $content, $utf8)" 2>nul
del "%TEMP_DIR%\raw_men.tmp" 2>nul

if not exist "%TEMP_DIR%\CaptureMenuPlugin.men" (
    echo [ERROR] Failed to extract menu file
    goto :cleanup_error
)
echo       ^> OK: CaptureMenuPlugin.men
echo.

:: ======================================================================================================================================================?
:: STEP 3: Auto-detect Cadence installation
:: ======================================================================================================================================================?
echo [3/5] Detecting Cadence Capture installation...

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
echo ====================================================================================================================================================================================?
echo =?Please enter your Cadence Capture installation path:      =?
echo =?                                                           =?
echo =?Example:                                                   =?
echo =?  C:\Cadence\Cadence_SPB_17.2-2016\tools\capture          =?
echo =?                                                           =?
echo ====================================================================================================================================================================================?
echo.
set /p CAPTURE_DIR="Capture path: "

:: Validate user input
if not exist "%CAPTURE_DIR%\tclscripts" (
    echo.
    echo [ERROR] Invalid path. Directory structure not recognized.
    echo        Expected to find: tclscripts subdirectory
    goto :cleanup_error
)

:found_cadence
if "%DETECTED%"=="1" (
    echo       ^> Auto-detected: %CAPTURE_DIR%
) else (
    echo       ^> User provided: %CAPTURE_DIR%
)
echo.

:: ======================================================================================================================================================?
:: STEP 4: Install files
:: ======================================================================================================================================================?
echo [4/5] Installing plugin files...

:: Install menu file
set "MENU_DIR=%CAPTURE_DIR%\menu"
if not exist "%MENU_DIR%" (
    mkdir "%MENU_DIR%"
    if errorlevel 1 (
        echo [ERROR] Cannot create menu directory
        echo        Permission denied: %MENU_DIR%
        goto :cleanup_error
    )
)

copy /Y "%TEMP_DIR%\CaptureMenuPlugin.men" "%MENU_DIR%\" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Failed to copy menu file
    echo        Check write permissions: %MENU_DIR%
    goto :cleanup_error
)
echo       ^> Installed: menu\CaptureMenuPlugin.men

:: Install TCL script to auto-load directory
set "TCL_DIR=%CAPTURE_DIR%\tclscripts\capAutoLoad"
if not exist "%TCL_DIR%" (
    mkdir "%TCL_DIR%"
    if errorlevel 1 (
        echo [ERROR] Cannot create TCL directory
        goto :cleanup_error
    )
)

copy /Y "%TEMP_DIR%\CaptureMenuPlugin.tcl" "%TCL_DIR%\" >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Failed to copy TCL script
    echo        Check write permissions: %TCL_DIR%
    goto :cleanup_error
)
echo       ^> Installed: tclscripts\capAutoLoad\CaptureMenuPlugin.tcl
echo.

:: ======================================================================================================================================================?
:: STEP 5: Cleanup and finish
:: ======================================================================================================================================================?
echo [5/5] Cleaning up temporary files...
rd /S /Q "%TEMP_DIR%" 2>nul
echo       ^> OK: Cleanup complete
echo.

:: ======================================================================================================================================================?
:: SUCCESS
:: ======================================================================================================================================================?
color 0A
cls
echo.
echo ========================================================================================================================================?
echo =?                                                           =?
echo =?             =?Installation Successful!                   =?
echo =?                                                           =?
echo ========================================================================================================================================?
echo.
echo =======================================================================================================================================
echo   Installation Summary
echo =======================================================================================================================================
echo.
echo   Installation Path:
echo     %CAPTURE_DIR%
echo.
echo   Installed Files:
echo     =?CaptureMenuPlugin.men   (Menu definition)
echo     =?CaptureMenuPlugin.tcl   (Auto-load script)
echo.
echo =======================================================================================================================================
echo   How to Use
echo =======================================================================================================================================
echo.
echo   1. Start Cadence Capture CIS
echo   2. Floating toolbar will appear automatically
echo      (or use menu: Tools ^> SVN Tools ^> Show Toolbar)
echo.
echo   Toolbar Buttons:
echo     [U] Green   - SVN Update   (Ctrl+U)
echo     [C] Blue    - SVN Commit   (Ctrl+M)
echo     [L] Orange  - SVN Cleanup
echo     [S] Gray    - Toggle Auto-Show Settings
echo.
echo =======================================================================================================================================
echo.
echo Installation location:
echo   %MENU_DIR%
echo   %TCL_DIR%
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:: ======================================================================================================================================================?
:: ERROR HANDLERS
:: ======================================================================================================================================================?

:cleanup_error
rd /S /Q "%TEMP_DIR%" 2>nul

:error_exit
color 0C
echo.
echo ========================================================================================================================================?
echo =?                                                           =?
echo =?             =?Installation Failed                        =?
echo =?                                                           =?
echo ========================================================================================================================================?
echo.
echo Please check:
echo   1. You have write permissions to Cadence directory
echo   2. Cadence Capture is not currently running
echo   3. The installation path is correct
echo.
echo For manual installation:
echo   1. Extract files to a temporary folder
echo   2. Run install_menu.bat as Administrator
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:: ======================================================================================================================================================?
:: UNINSTALL SECTION
:: ======================================================================================================================================================?

:uninstall
cls
color 0C
echo.
echo =======================================================================================================================================
echo   Uninstallation Mode
echo =======================================================================================================================================
echo.
echo This will REMOVE the SVN Plugin from Cadence Capture.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

cls
echo.
echo =======================================================================================================================================
echo   Uninstallation Progress
echo =======================================================================================================================================
echo.

:: Detect Cadence installation
echo [1/3] Detecting Cadence Capture installation...

set "CAPTURE_DIR="
set "DETECTED=0"

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
        goto :uninstall_found_cadence
    )
)

:uninstall_not_found_cadence
echo.
echo       [WARNING] Automatic detection failed
echo.
set /p CAPTURE_DIR="Enter Cadence Capture path: "

if not exist "%CAPTURE_DIR%\tclscripts" (
    echo.
    echo [ERROR] Invalid path.
    goto :error_exit
)

:uninstall_found_cadence
if "%DETECTED%"=="1" (
    echo       ^> Auto-detected: %CAPTURE_DIR%
) else (
    echo       ^> User provided: %CAPTURE_DIR%
)
echo.

:: Check for installed files
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
    color 0E
    echo =======================================================================================================================================
    echo   Plugin is not installed or already removed.
    echo =======================================================================================================================================
    echo.
    echo Press any key to return to menu...
    pause >nul
    goto :start_menu
)
echo.

:: Remove files
echo [3/3] Removing plugin files...

set "REMOVED=0"

if exist "%MENU_FILE%" (
    del /F /Q "%MENU_FILE%" 2>nul
    if not exist "%MENU_FILE%" (
        echo       ^> Removed: menu\CaptureMenuPlugin.men
        set "REMOVED=1"
    ) else (
        echo       [ERROR] Cannot delete: %MENU_FILE%
    )
)

if exist "%TCL_FILE%" (
    del /F /Q "%TCL_FILE%" 2>nul
    if not exist "%TCL_FILE%" (
        echo       ^> Removed: tclscripts\capAutoLoad\CaptureMenuPlugin.tcl
        set "REMOVED=1"
    ) else (
        echo       [ERROR] Cannot delete: %TCL_FILE%
    )
)

if "%REMOVED%"=="0" (
    goto :error_exit
)

echo.

:: Uninstall success
color 0A
cls
echo.
echo ========================================================================================================================================?
echo =?                                                           =?
echo =?          =?Uninstallation Successful!                    =?
echo =?                                                           =?
echo ========================================================================================================================================?
echo.
echo =======================================================================================================================================
echo   Uninstallation Summary
echo =======================================================================================================================================
echo.
echo   Removed from:
echo     %CAPTURE_DIR%
echo.
echo   The SVN Plugin has been completely removed.
echo.
echo   Note:
echo     =?Configuration files in project directories are preserved
echo     =?You can delete them manually if needed
echo.
echo =======================================================================================================================================
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:: ======================================================================================================================================================?
:: EMBEDDED FILE DATA
:: DO NOT MODIFY BELOW THIS LINE
:: ======================================================================================================================================================?

