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


::MEN_START::
::MEN::MENU "&Tools"
::MEN::BEGIN
::MEN::    POPUP "&SVN Tools"
::MEN::    BEGIN
::MEN::        MENUITEM "Show Toolbar", "_cdnMenuPluginShowMenu", ""
::MEN::        MENUITEM "-", 0, ""
::MEN::        MENUITEM "SVN Update\tCtrl+U", "_cdnMenuPluginSvnUpdate", ""
::MEN::        MENUITEM "SVN Commit\tCtrl+M", "_cdnMenuPluginSvnCommit", ""
::MEN::        MENUITEM "-", 0, ""
::MEN::        MENUITEM "Settings...", "_cdnMenuPluginSettings", ""
::MEN::        MENUITEM "About", "_cdnMenuPluginAbout", ""
::MEN::    END
::MEN::END
::MEN::ACCEL "Ctrl+U", "_cdnMenuPluginSvnUpdate"
::MEN::ACCEL "Ctrl+M", "_cdnMenuPluginSvnCommit"
::MEN_END::

::TCL_START::
::TCL::#
::TCL::# Cadence Capture SVN Plugin (Simplified)
::TCL::# Date: 2025-12-04
::TCL::#
::TCL::package require Tcl 8.4
::TCL::# Create namespace
::TCL::namespace eval ::CaptureMenuPlugin {
::TCL::    variable SvnPath "svn"
::TCL::    variable autoShow 1
::TCL::    variable configFile ""
::TCL::    variable logFile ""
::TCL::}
::TCL::# Initialize log file
::TCL::proc ::CaptureMenuPlugin::InitLog {} {
::TCL::    variable logFile
::TCL::    if {$logFile eq ""} {
::TCL::        set logFile [file join [pwd] "capture_svn_plugin.log"]
::TCL::    }
::TCL::}
::TCL::# Write log message (disabled for production)
::TCL::proc ::CaptureMenuPlugin::Log {msg} {
::TCL::    # Logging disabled
::TCL::    return
::TCL::}
::TCL::# Get config file path
::TCL::proc ::CaptureMenuPlugin::GetConfigFile {} {
::TCL::    variable configFile
::TCL::    if {$configFile eq ""} {
::TCL::        if {[info exists ::env(USERPROFILE)]} {
::TCL::            set configFile [file join $::env(USERPROFILE) ".capture_svn_config"]
::TCL::        } elseif {[info exists ::env(HOME)]} {
::TCL::            set configFile [file join $::env(HOME) ".capture_svn_config"]
::TCL::        } else {
::TCL::            set configFile [file join [pwd] ".capture_svn_config"]
::TCL::        }
::TCL::    }
::TCL::    return $configFile
::TCL::}
::TCL::# Load configuration
::TCL::proc ::CaptureMenuPlugin::LoadConfig {} {
::TCL::    variable autoShow
::TCL::    set autoShow 1
::TCL::    set cfgFile [::CaptureMenuPlugin::GetConfigFile]
::TCL::    if {[file exists $cfgFile]} {
::TCL::        if {[catch {
::TCL::            set fp [open $cfgFile r]
::TCL::            set content [read $fp]
::TCL::            close $fp
::TCL::            foreach line [split $content "\n"] {
::TCL::                if {[regexp {^autoShow=([01])$} $line -> value]} {
::TCL::                    set autoShow $value
::TCL::                }
::TCL::            }
::TCL::        }]} {
::TCL::            set autoShow 1
::TCL::        }
::TCL::    }
::TCL::}
::TCL::# Save configuration
::TCL::proc ::CaptureMenuPlugin::SaveConfig {} {
::TCL::    variable autoShow
::TCL::    set cfgFile [::CaptureMenuPlugin::GetConfigFile]
::TCL::    if {[catch {
::TCL::        set fp [open $cfgFile w]
::TCL::        puts $fp "autoShow=$autoShow"
::TCL::        close $fp
::TCL::    }]} {
::TCL::        # Ignore save errors
::TCL::    }
::TCL::}
::TCL::# Toggle auto-show setting
::TCL::proc ::CaptureMenuPlugin::ToggleAutoShow {} {
::TCL::    variable autoShow
::TCL::    set autoShow [expr {!$autoShow}]
::TCL::    ::CaptureMenuPlugin::SaveConfig
::TCL::    
::TCL::    if {[catch {package require Tk}]} {
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    set msg [expr {$autoShow ? "Auto-show enabled: Toolbar will show on startup" : "Auto-show disabled: Toolbar will NOT show on startup"}]
::TCL::    catch {
::TCL::        tk_messageBox -title "Settings" -message $msg -type ok -icon info
::TCL::    }
::TCL::}
::TCL::# Get SVN executable path
::TCL::proc ::CaptureMenuPlugin::GetSvnPath {} {
::TCL::    variable SvnPath
::TCL::    
::TCL::    set commonPaths {
::TCL::        "C:/Program Files/TortoiseSVN/bin/svn.exe"
::TCL::        "C:/Program Files (x86)/TortoiseSVN/bin/svn.exe"
::TCL::    }
::TCL::    
::TCL::    if {$SvnPath ne "svn" && [file exists $SvnPath]} {
::TCL::        return $SvnPath
::TCL::    }
::TCL::    
::TCL::    foreach path $commonPaths {
::TCL::        if {[file exists $path]} {
::TCL::            set SvnPath $path
::TCL::            return $path
::TCL::        }
::TCL::    }
::TCL::    
::TCL::    if {![catch {exec where.exe svn 2>NUL} result]} {
::TCL::        set foundPath [string trim [lindex [split $result "\n"] 0]]
::TCL::        if {$foundPath ne ""} {
::TCL::            return $foundPath
::TCL::        }
::TCL::    }
::TCL::    
::TCL::    if {[file exists "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"]} {
::TCL::        return "TORTOISE"
::TCL::    }
::TCL::    
::TCL::    return ""
::TCL::}
::TCL::# Check if directory is SVN working copy
::TCL::proc ::CaptureMenuPlugin::IsSvnWorkingCopy {path} {
::TCL::    set svnDir [file join $path ".svn"]
::TCL::    if {[file exists $svnDir] && [file isdirectory $svnDir]} {
::TCL::        return 1
::TCL::    }
::TCL::    
::TCL::    set currentPath $path
::TCL::    for {set i 0} {$i < 5} {incr i} {
::TCL::        set parentPath [file dirname $currentPath]
::TCL::        if {$parentPath == $currentPath} { break }
::TCL::        set svnDir [file join $parentPath ".svn"]
::TCL::        if {[file exists $svnDir] && [file isdirectory $svnDir]} {
::TCL::            return 1
::TCL::        }
::TCL::        set currentPath $parentPath
::TCL::    }
::TCL::    
::TCL::    return 0
::TCL::}
::TCL::# Get design file path
::TCL::proc ::CaptureMenuPlugin::GetDesignPath {} {
::TCL::    catch {
::TCL::        set session [DboSession_GetInstance]
::TCL::        if {$session != ""} {
::TCL::            set design [$session GetActiveDesign]
::TCL::            if {$design != ""} {
::TCL::                set schematic [$design GetRootSchematic]
::TCL::                if {$schematic != ""} {
::TCL::                    set dsnFile [$schematic GetPath]
::TCL::                    if {$dsnFile != ""} {
::TCL::                        return [file dirname $dsnFile]
::TCL::                    }
::TCL::                }
::TCL::            }
::TCL::        }
::TCL::    }
::TCL::    return [pwd]
::TCL::}
::TCL::# Show message box
::TCL::proc ShowMessage {msg title {type 0}} {
::TCL::    if {![catch {package require Tk}]} {
::TCL::        catch {wm withdraw .}
::TCL::        if {$type == 4} {
::TCL::            set answer [tk_messageBox -type yesno -icon question -title $title -message $msg -parent .]
::TCL::            return [expr {$answer eq "yes" ? 6 : 7}]
::TCL::        } else {
::TCL::            tk_messageBox -type ok -icon info -title $title -message $msg -parent .
::TCL::            return 1
::TCL::        }
::TCL::    }
::TCL::    return 1
::TCL::}
::TCL::# SVN Update Command
::TCL::proc ::CaptureMenuPlugin::SvnUpdate {} {
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: Starting..."
::TCL::    set designPath [::CaptureMenuPlugin::GetDesignPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: Design path = $designPath"
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: Checking if SVN working copy..."
::TCL::    set isSvn 0
::TCL::    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
::TCL::        ::CaptureMenuPlugin::Log "SvnUpdate: IsSvnWorkingCopy failed: $err"
::TCL::        ShowMessage "Error checking SVN status:\n$err" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: IsSvnWorkingCopy returned: $isSvn"
::TCL::    
::TCL::    if {!$isSvn} {
::TCL::        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: Getting SVN path..."
::TCL::    set svnExe [::CaptureMenuPlugin::GetSvnPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnUpdate: SVN path = $svnExe"
::TCL::    
::TCL::    if {$svnExe == ""} {
::TCL::        ::CaptureMenuPlugin::Log "SvnUpdate: SVN not found!"
::TCL::        ShowMessage "SVN not found!" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {$svnExe == "TORTOISE"} {
::TCL::        ::CaptureMenuPlugin::Log "SvnUpdate: Using TortoiseSVN..."
::TCL::        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
::TCL::        set cmdLine [list $tortoisePath /command:update /path:$designPath /closeonend:0]
::TCL::        ::CaptureMenuPlugin::Log "SvnUpdate: Executing: $cmdLine"
::TCL::        if {[catch { eval exec $cmdLine & } err]} {
::TCL::            ::CaptureMenuPlugin::Log "SvnUpdate: Execution failed: $err"
::TCL::        } else {
::TCL::            ::CaptureMenuPlugin::Log "SvnUpdate: TortoiseSVN launched successfully"
::TCL::        }
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {[catch {
::TCL::        set output [exec $svnExe update "$designPath" 2>@1]
::TCL::        ShowMessage "SVN Update completed\n\n$output" "Success" 0
::TCL::    } err]} {
::TCL::        ShowMessage "Update failed:\n$err" "Error" 0
::TCL::    }
::TCL::}
::TCL::# SVN Commit Command
::TCL::proc ::CaptureMenuPlugin::SvnCommit {} {
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: Starting..."
::TCL::    set designPath [::CaptureMenuPlugin::GetDesignPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: Design path = $designPath"
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: Checking if SVN working copy..."
::TCL::    set isSvn 0
::TCL::    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCommit: IsSvnWorkingCopy failed: $err"
::TCL::        ShowMessage "Error checking SVN status:\n$err" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: IsSvnWorkingCopy returned: $isSvn"
::TCL::    
::TCL::    if {!$isSvn} {
::TCL::        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: Getting SVN path..."
::TCL::    set svnExe [::CaptureMenuPlugin::GetSvnPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnCommit: SVN path = $svnExe"
::TCL::    
::TCL::    if {$svnExe == ""} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCommit: SVN not found!"
::TCL::        ShowMessage "SVN not found!" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {$svnExe == "TORTOISE"} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCommit: Using TortoiseSVN..."
::TCL::        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
::TCL::        set cmdLine [list $tortoisePath /command:commit /path:$designPath /closeonend:0]
::TCL::        ::CaptureMenuPlugin::Log "SvnCommit: Executing: $cmdLine"
::TCL::        if {[catch { eval exec $cmdLine & } err]} {
::TCL::            ::CaptureMenuPlugin::Log "SvnCommit: Execution failed: $err"
::TCL::        } else {
::TCL::            ::CaptureMenuPlugin::Log "SvnCommit: TortoiseSVN launched successfully"
::TCL::        }
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {[catch {
::TCL::        set output [exec $svnExe commit "$designPath" 2>@1]
::TCL::        ShowMessage "SVN Commit completed\n\n$output" "Success" 0
::TCL::    } err]} {
::TCL::        ShowMessage "Commit failed:\n$err" "Error" 0
::TCL::    }
::TCL::}
::TCL::# SVN Cleanup Command
::TCL::proc ::CaptureMenuPlugin::SvnCleanup {} {
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: Starting..."
::TCL::    set designPath [::CaptureMenuPlugin::GetDesignPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: Design path = $designPath"
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: Checking if SVN working copy..."
::TCL::    set isSvn 0
::TCL::    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCleanup: IsSvnWorkingCopy failed: $err"
::TCL::        ShowMessage "Error checking SVN status:\n$err" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: IsSvnWorkingCopy returned: $isSvn"
::TCL::    
::TCL::    if {!$isSvn} {
::TCL::        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: Getting SVN path..."
::TCL::    set svnExe [::CaptureMenuPlugin::GetSvnPath]
::TCL::    ::CaptureMenuPlugin::Log "SvnCleanup: SVN path = $svnExe"
::TCL::    
::TCL::    if {$svnExe == ""} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCleanup: SVN not found!"
::TCL::        ShowMessage "SVN not found!" "Error" 0
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {$svnExe == "TORTOISE"} {
::TCL::        ::CaptureMenuPlugin::Log "SvnCleanup: Using TortoiseSVN..."
::TCL::        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
::TCL::        set cmdLine [list $tortoisePath /command:cleanup /path:$designPath /closeonend:0]
::TCL::        ::CaptureMenuPlugin::Log "SvnCleanup: Executing: $cmdLine"
::TCL::        if {[catch { eval exec $cmdLine & } err]} {
::TCL::            ::CaptureMenuPlugin::Log "SvnCleanup: Execution failed: $err"
::TCL::        } else {
::TCL::            ::CaptureMenuPlugin::Log "SvnCleanup: TortoiseSVN launched successfully"
::TCL::        }
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    if {[catch {
::TCL::        set output [exec $svnExe cleanup "$designPath" 2>@1]
::TCL::        ShowMessage "SVN Cleanup completed\n\n$output" "Success" 0
::TCL::    } err]} {
::TCL::        ShowMessage "Cleanup failed:\n$err" "Error" 0
::TCL::    }
::TCL::}
::TCL::# Settings
::TCL::proc ::CaptureMenuPlugin::Settings {} {
::TCL::    set svnExe [::CaptureMenuPlugin::GetSvnPath]
::TCL::    
::TCL::    set msg "Cadence Capture SVN Plugin\nVersion: 1.0.1\nDate: 2025-12-04\n\n"
::TCL::    
::TCL::    if {$svnExe == "TORTOISE"} {
::TCL::        append msg "Mode: TortoiseSVN GUI\nPath: C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
::TCL::    } elseif {$svnExe == ""} {
::TCL::        append msg "SVN Status: NOT FOUND"
::TCL::    } else {
::TCL::        append msg "Mode: Command Line\nPath: $svnExe"
::TCL::    }
::TCL::    
::TCL::    ShowMessage $msg "Settings" 0
::TCL::}
::TCL::# About
::TCL::proc ::CaptureMenuPlugin::About {} {
::TCL::    ShowMessage "Cadence Capture SVN Plugin\n\nVersion: 1.0.1\nDate: 2025-12-04\n\nSimple SVN integration" "About" 0
::TCL::}
::TCL::# Create floating menu window
::TCL::proc ::CaptureMenuPlugin::CreateMenuWindow {} {
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Starting..."
::TCL::    
::TCL::    if {[catch {package require Tk} err]} {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Failed to load Tk - $err"
::TCL::        return
::TCL::    }
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Tk loaded successfully"
::TCL::    
::TCL::    # Withdraw the root window completely
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Attempting to withdraw root window"
::TCL::    catch {
::TCL::        wm withdraw .
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Root window withdrawn - wm withdraw executed"
::TCL::        wm attributes . -alpha 0.0
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Root window alpha set to 0.0"
::TCL::    }
::TCL::    
::TCL::    if {[winfo exists .svnMenu]} {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: .svnMenu already exists, showing it"
::TCL::        wm deiconify .svnMenu
::TCL::        raise .svnMenu
::TCL::        return
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Creating new .svnMenu window"
::TCL::    
::TCL::    if {[catch {
::TCL::        set screenWidth [winfo screenwidth .]
::TCL::        set screenHeight [winfo screenheight .]
::TCL::    }]} {
::TCL::        set screenWidth 1920
::TCL::        set screenHeight 1080
::TCL::    }
::TCL::    
::TCL::    # Calculate taskbar height
::TCL::    set taskbarHeight 40
::TCL::    if {[catch {
::TCL::        # Get work area (screen minus taskbar)
::TCL::        set workHeight [winfo vrootheight .]
::TCL::        if {$workHeight > 0 && $workHeight < $screenHeight} {
::TCL::            set taskbarHeight [expr {$screenHeight - $workHeight}]
::TCL::            ::CaptureMenuPlugin::Log "CreateMenuWindow: Detected taskbar height = $taskbarHeight"
::TCL::        }
::TCL::    }]} {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Using default taskbar height = $taskbarHeight"
::TCL::    }
::TCL::    
::TCL::    set winWidth 200
::TCL::    set winHeight 25
::TCL::    set xPos [expr {$screenWidth - $winWidth - 5}]
::TCL::    set yPos [expr {$screenHeight - $winHeight - $taskbarHeight - 21}]
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Screen=${screenWidth}x${screenHeight}, Taskbar=${taskbarHeight}, Pos=${xPos},${yPos}"
::TCL::    
::TCL::    # Create as toplevel but make it a utility window
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Creating toplevel .svnMenu"
::TCL::    toplevel .svnMenu -class "TkSvnToolbar"
::TCL::    
::TCL::    # DON'T use transient - it causes geometry issues when parent is withdrawn
::TCL::    # Just rely on -toolwindow to remove taskbar icon
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Skipping transient (causes geometry bug with withdrawn parent)"
::TCL::    
::TCL::    # Now set window attributes
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting window title"
::TCL::    wm title .svnMenu "SVN"
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting geometry ${winWidth}x${winHeight}+${xPos}+${yPos}"
::TCL::    wm geometry .svnMenu "${winWidth}x${winHeight}+${xPos}+${yPos}"
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting resizable 0 0"
::TCL::    wm resizable .svnMenu 0 0
::TCL::    
::TCL::    # Create button frame directly (no custom title bar)
::TCL::    frame .svnMenu.f -bg "#f0f0f0"
::TCL::    pack .svnMenu.f -fill both -expand 1
::TCL::    
::TCL::    # SVN Update button (icon style)
::TCL::    button .svnMenu.f.update -text "U" \
::TCL::        -command {
::TCL::            ::CaptureMenuPlugin::Log "Button: Update clicked"
::TCL::            ::CaptureMenuPlugin::SvnUpdate
::TCL::        } \
::TCL::        -width 2 \
::TCL::        -bg "#4CAF50" -fg white -font {Arial 8 bold} \
::TCL::        -activebackground "#45a049" \
::TCL::        -relief raised -borderwidth 1
::TCL::    pack .svnMenu.f.update -side left -padx 1 -pady 1
::TCL::    
::TCL::    # SVN Commit button (icon style)
::TCL::    button .svnMenu.f.commit -text "C" \
::TCL::        -command {
::TCL::            ::CaptureMenuPlugin::Log "Button: Commit clicked"
::TCL::            ::CaptureMenuPlugin::SvnCommit
::TCL::        } \
::TCL::        -width 2 \
::TCL::        -bg "#2196F3" -fg white -font {Arial 8 bold} \
::TCL::        -activebackground "#0b7dda" \
::TCL::        -relief raised -borderwidth 1
::TCL::    pack .svnMenu.f.commit -side left -padx 1 -pady 1
::TCL::    
::TCL::    # SVN Cleanup button (icon style)
::TCL::    button .svnMenu.f.cleanup -text "L" \
::TCL::        -command {
::TCL::            ::CaptureMenuPlugin::Log "Button: Cleanup clicked"
::TCL::            ::CaptureMenuPlugin::SvnCleanup
::TCL::        } \
::TCL::        -width 2 \
::TCL::        -bg "#FF9800" -fg white -font {Arial 8 bold} \
::TCL::        -activebackground "#e68900" \
::TCL::        -relief raised -borderwidth 1
::TCL::    pack .svnMenu.f.cleanup -side left -padx 1 -pady 1
::TCL::    
::TCL::    # Settings button (icon style)
::TCL::    button .svnMenu.f.settings -text "S" \
::TCL::        -command {
::TCL::            ::CaptureMenuPlugin::Log "Button: Settings clicked"
::TCL::            ::CaptureMenuPlugin::ToggleAutoShow
::TCL::        } \
::TCL::        -width 2 \
::TCL::        -bg "#9E9E9E" -fg white -font {Arial 8 bold} \
::TCL::        -activebackground "#757575" \
::TCL::        -relief raised -borderwidth 1
::TCL::    pack .svnMenu.f.settings -side left -padx 1 -pady 1
::TCL::    
::TCL::    # ALL content created - now set window attributes
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: All content created, now setting window attributes"
::TCL::    
::TCL::    # First ensure geometry is properly set
::TCL::    update idletasks
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: After update idletasks, geometry: [wm geometry .svnMenu]"
::TCL::    
::TCL::    # Force geometry again to make sure
::TCL::    wm geometry .svnMenu "${winWidth}x${winHeight}+${xPos}+${yPos}"
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Geometry reset to ${winWidth}x${winHeight}+${xPos}+${yPos}"
::TCL::    
::TCL::    # Now set window decorations
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Trying -toolwindow 1"
::TCL::    if {[catch {wm attributes .svnMenu -toolwindow 1} err]} {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: -toolwindow failed: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: -toolwindow succeeded"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting -topmost 1"
::TCL::    wm attributes .svnMenu -topmost 1
::TCL::    
::TCL::    # DON'T use overrideredirect - it causes 1x1 geometry bug on Windows
::TCL::    # Instead rely on -toolwindow which removes taskbar icon
::TCL::    # System title bar will be hidden by our custom title bar covering it
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Skipping overrideredirect due to Windows Tk geometry bug"
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Final geometry: [wm geometry .svnMenu]"
::TCL::    
::TCL::    # Now show the window
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Showing window"
::TCL::    wm deiconify .svnMenu
::TCL::    raise .svnMenu
::TCL::    update
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "CreateMenuWindow: Window created successfully at ${xPos},${yPos} size ${winWidth}x${winHeight}"
::TCL::    if {[catch {set mapped [winfo ismapped .svnMenu]} err]} {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Window state - exists: [winfo exists .svnMenu], ismapped error: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "CreateMenuWindow: Window state - visible: $mapped, exists: [winfo exists .svnMenu]"
::TCL::    }
::TCL::}
::TCL::# Show/Hide menu
::TCL::proc ::CaptureMenuPlugin::ShowMenu {} {
::TCL::    if {[catch {package require Tk}]} {
::TCL::        return
::TCL::    }
::TCL::    if {[winfo exists .svnMenu]} {
::TCL::        wm deiconify .svnMenu
::TCL::        raise .svnMenu
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::CreateMenuWindow
::TCL::    }
::TCL::}
::TCL::proc ::CaptureMenuPlugin::HideMenu {} {
::TCL::    if {[catch {package require Tk}]} {
::TCL::        return
::TCL::    }
::TCL::    if {[winfo exists .svnMenu]} {
::TCL::        wm withdraw .svnMenu
::TCL::    }
::TCL::}
::TCL::# Load config and auto-show on startup
::TCL::::CaptureMenuPlugin::Log "=== Plugin Loading ==="
::TCL::# Force autoShow to enabled
::TCL::namespace eval ::CaptureMenuPlugin {
::TCL::    variable autoShow
::TCL::    set autoShow 1
::TCL::}
::TCL::# Always show menu on startup
::TCL::::CaptureMenuPlugin::Log "Attempting to show menu..."
::TCL::# Load Tk package
::TCL::set tkLoaded 0
::TCL::if {[catch {package require Tk} tkVersion]} {
::TCL::    ::CaptureMenuPlugin::Log "Tk package load failed: $tkVersion"
::TCL::} else {
::TCL::    ::CaptureMenuPlugin::Log "Tk package loaded successfully, version: $tkVersion"
::TCL::    set tkLoaded 1
::TCL::}
::TCL::if {$tkLoaded} {
::TCL::    # Try immediate show
::TCL::    ::CaptureMenuPlugin::Log "Calling ShowMenu immediately..."
::TCL::    catch {::CaptureMenuPlugin::ShowMenu} err
::TCL::    if {$err ne ""} {
::TCL::        ::CaptureMenuPlugin::Log "Immediate ShowMenu error: $err"
::TCL::    }
::TCL::    
::TCL::    # Also schedule delayed show as backup
::TCL::    after 500 {
::TCL::        ::CaptureMenuPlugin::Log "Delayed ShowMenu (500ms)"
::TCL::        catch {::CaptureMenuPlugin::ShowMenu}
::TCL::    }
::TCL::    
::TCL::    after 1500 {
::TCL::        ::CaptureMenuPlugin::Log "Delayed ShowMenu (1500ms)"
::TCL::        catch {::CaptureMenuPlugin::ShowMenu}
::TCL::    }
::TCL::}
::TCL::# Register menu commands
::TCL::::CaptureMenuPlugin::Log "=== Starting Menu Command Registration ==="
::TCL::set tkAvailable 0
::TCL::if {[catch {package require Tk} tkVer]} {
::TCL::    ::CaptureMenuPlugin::Log "Tk package NOT available - error: $tkVer"
::TCL::} else {
::TCL::    set tkAvailable 1
::TCL::    ::CaptureMenuPlugin::Log "Tk package available (version $tkVer) for menu registration"
::TCL::}
::TCL::if {$tkAvailable} {
::TCL::    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSvnUpdate"
::TCL::    if {[catch {RegisterAction "_cdnMenuPluginSvnUpdate" "::CaptureMenuPlugin::SvnUpdate" "" "" ""} err]} {
::TCL::        ::CaptureMenuPlugin::Log "Failed to register SvnUpdate: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "Successfully registered SvnUpdate"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSvnCommit"
::TCL::    if {[catch {RegisterAction "_cdnMenuPluginSvnCommit" "::CaptureMenuPlugin::SvnCommit" "" "" ""} err]} {
::TCL::        ::CaptureMenuPlugin::Log "Failed to register SvnCommit: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "Successfully registered SvnCommit"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginShowMenu"
::TCL::    if {[catch {RegisterAction "_cdnMenuPluginShowMenu" "::CaptureMenuPlugin::ShowMenu" "" "" ""} err]} {
::TCL::        ::CaptureMenuPlugin::Log "Failed to register ShowMenu: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "Successfully registered ShowMenu"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSettings"
::TCL::    if {[catch {RegisterAction "_cdnMenuPluginSettings" "::CaptureMenuPlugin::Settings" "" "" ""} err]} {
::TCL::        ::CaptureMenuPlugin::Log "Failed to register Settings: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "Successfully registered Settings"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginAbout"
::TCL::    if {[catch {RegisterAction "_cdnMenuPluginAbout" "::CaptureMenuPlugin::About" "" "" ""} err]} {
::TCL::        ::CaptureMenuPlugin::Log "Failed to register About: $err"
::TCL::    } else {
::TCL::        ::CaptureMenuPlugin::Log "Successfully registered About"
::TCL::    }
::TCL::    
::TCL::    ::CaptureMenuPlugin::Log "Menu command registration complete"
::TCL::} else {
::TCL::    ::CaptureMenuPlugin::Log "Skipping menu registration - Tk not available"
::TCL::}
::TCL::::CaptureMenuPlugin::Log "=== Plugin Load Complete ==="
::TCL_END::
