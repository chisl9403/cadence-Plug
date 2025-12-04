@echo off
setlocal disabledelayedexpansion

echo ============================================================
echo   Building Standalone Installer
echo ============================================================
echo.

set "OUTPUT=CadenceSVNPlugin_Standalone.bat"
set "TEMPLATE=installer_template.bat"
set "TEMP_BUILD=%TEMP%\build_standalone_%RANDOM%.bat"

:: Start with clean template
copy /Y "%TEMPLATE%" "%TEMP_BUILD%" >nul

:: Append MEN file with markers
echo.
echo [1/2] Embedding CaptureMenuPlugin.men...
echo.>> "%TEMP_BUILD%"
echo ::MEN_START::>> "%TEMP_BUILD%"
for /f "usebackq delims=" %%l in ("CaptureMenuPlugin.men") do (
    echo ::MEN::%%l>> "%TEMP_BUILD%"
)
echo ::MEN_END::>> "%TEMP_BUILD%"
echo [OK] Menu file embedded

:: Append TCL file with markers
echo.
echo [2/2] Embedding CaptureMenuPlugin.tcl...
echo.>> "%TEMP_BUILD%"
echo ::TCL_START::>> "%TEMP_BUILD%"
for /f "usebackq delims=" %%l in ("CaptureMenuPlugin.tcl") do (
    echo ::TCL::%%l>> "%TEMP_BUILD%"
)
echo ::TCL_END::>> "%TEMP_BUILD%"
echo [OK] TCL script embedded

:: Replace original with built version
move /Y "%TEMP_BUILD%" "%OUTPUT%" >nul

echo.
echo ============================================================
echo   Build Complete!
echo ============================================================
echo.
echo Output: %OUTPUT%
echo Size: 
powershell -NoProfile -Command "(Get-Item '%OUTPUT%').Length / 1KB | ForEach-Object { '{0:N2} KB' -f $_ }"
echo.
echo ------------------------------------------------------------
echo This is a STANDALONE installer:
echo.
echo  - Can run from ANY location (USB, network, download)
echo  - No dependencies or extraction needed
echo  - Auto-detects Cadence installation
echo  - User-friendly console interface
echo  - All files embedded in single .bat file
echo.
echo Distribution:
echo  Simply send %OUTPUT% to users
echo  They double-click to install
echo ------------------------------------------------------------
echo.
echo Build complete. File ready for distribution.
echo.
